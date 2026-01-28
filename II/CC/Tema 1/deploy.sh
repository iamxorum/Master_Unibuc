#!/bin/bash

RESOURCE_GROUP="rg-staticweb-dev"
LOCATION="westeurope"
STORAGE_ACCOUNT=""
CONTAINER="\$web"

set -e

function create_storage() {
    while [ -z "$STORAGE_ACCOUNT" ]; do
        read -p "Enter new storage account name (must be globally unique, 3-24 chars, lowercase): " STORAGE_ACCOUNT
        if [ -z "$STORAGE_ACCOUNT" ]; then
            echo "Storage account name cannot be empty."
        elif [ ${#STORAGE_ACCOUNT} -lt 3 ] || [ ${#STORAGE_ACCOUNT} -gt 24 ]; then
            echo "Storage account name must be between 3 and 24 characters."
            STORAGE_ACCOUNT=""
        elif [[ ! "$STORAGE_ACCOUNT" =~ ^[a-z0-9]+$ ]]; then
            echo "Storage account name can only contain lowercase letters and numbers."
            STORAGE_ACCOUNT=""
        fi
    done

    echo "Creating resource group (if not exists)..."
    if ! az group create --name "$RESOURCE_GROUP" --location "$LOCATION" >/dev/null 2>&1; then
        echo "Failed to create resource group. Please check your Azure CLI login and permissions."
        return 1
    fi

    echo "Creating storage account..."
    if ! az storage account create \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --allow-blob-public-access true; then
        echo "Failed to create storage account. Name might already be taken."
        return 1
    fi

    echo "Waiting for storage account to be fully provisioned..."
    sleep 10

    echo "Enabling static website hosting..."
    if az storage blob service-properties update \
        --account-name "$STORAGE_ACCOUNT" \
        --static-website \
        --index-document index.html \
        --auth-mode login >/dev/null 2>&1; then
        echo "Static website hosting enabled successfully with Azure AD auth."
    else
        echo "Azure AD auth failed, trying with account key..."
        local account_key=$(az storage account keys list --resource-group "$RESOURCE_GROUP" --account-name "$STORAGE_ACCOUNT" --query "[0].value" -o tsv)
        if [ -n "$account_key" ] && az storage blob service-properties update \
            --account-name "$STORAGE_ACCOUNT" \
            --account-key "$account_key" \
            --static-website \
            --index-document index.html >/dev/null 2>&1; then
            echo "Static website hosting enabled successfully with account key."
        else
            echo "Warning: Failed to enable static website hosting automatically."
            echo "You can enable it manually in the Azure portal or try again later."
            echo "The storage account was created successfully."
        fi
    fi

    local website_url=$(az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --query "primaryEndpoints.web" -o tsv)
    echo "Storage account created and static site enabled."
    echo "Your website URL: $website_url"
}

function upload_files() {
    if [ -z "$STORAGE_ACCOUNT" ]; then 
        if ! pick_storage_account; then
            return 1
        fi
    fi
    
    read -p "Enter the folder to upload (default .): " FOLDER
    FOLDER=${FOLDER:-.}
    
    if [ ! -d "$FOLDER" ]; then
        echo "Directory '$FOLDER' does not exist."
        return 1
    fi

    echo "Uploading files from '$FOLDER' to $STORAGE_ACCOUNT..."
    if ! az storage blob upload-batch \
        --destination "$CONTAINER" \
        --source "$FOLDER" \
        --account-name "$STORAGE_ACCOUNT" \
        --overwrite; then
        echo "Upload failed. Please check your permissions and storage account."
        return 1
    fi

    local website_url=$(az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --query "primaryEndpoints.web" -o tsv 2>/dev/null)
    echo "Upload finished."
    if [ -n "$website_url" ]; then
        echo "Your website is available at: $website_url"
    fi
}

function delete_blob() {
    if [ -z "$STORAGE_ACCOUNT" ]; then 
        if ! pick_storage_account; then
            return 1
        fi
    fi
    
    local BLOB=""
    while [ -z "$BLOB" ]; do
        read -p "Enter blob name to delete: " BLOB
        if [ -z "$BLOB" ]; then
            echo "Blob name cannot be empty."
        fi
    done

    if ! az storage blob delete \
        --container-name "$CONTAINER" \
        --name "$BLOB" \
        --account-name "$STORAGE_ACCOUNT"; then
        echo "Failed to delete blob. Please check if the blob exists."
        return 1
    fi

    echo "Blob '$BLOB' deleted successfully."
}

function list_blobs() {
    if [ -z "$STORAGE_ACCOUNT" ]; then 
        if ! pick_storage_account; then
            return 1
        fi
    fi

    echo "Blobs in $STORAGE_ACCOUNT:"
    local blobs=$(az storage blob list \
        --container-name "$CONTAINER" \
        --account-name "$STORAGE_ACCOUNT" \
        --query "[].name" -o tsv 2>/dev/null)
    
    if [ -z "$blobs" ]; then
        echo "No blobs found or unable to access storage account."
        return 1
    fi
    
    echo "$blobs"
}

function get_storage_info() {
    if [ -z "$STORAGE_ACCOUNT" ]; then 
        if ! pick_storage_account; then
            return 1
        fi
    fi
    
    echo "Getting information for storage account '$STORAGE_ACCOUNT'..."
    echo ""
    
    local info=$(az storage account show --name "$STORAGE_ACCOUNT" --query "{name:name,resourceGroup:resourceGroup,location:location,sku:sku.name,kind:kind,creationTime:creationTime,primaryLocation:primaryLocation}" -o table 2>/dev/null)
    
    if [ -z "$info" ]; then
        echo "Failed to get storage account information. Please check if the account exists and you have permissions."
        return 1
    fi
    
    echo "=== Storage Account Details ==="
    echo "$info"
    echo ""
    
    local website_info=$(az storage blob service-properties show --account-name "$STORAGE_ACCOUNT" --query "staticWebsite" 2>/dev/null)
    if [ "$website_info" != "null" ] && [ -n "$website_info" ]; then
        echo "=== Static Website Configuration ==="
        local website_url=$(az storage account show --name "$STORAGE_ACCOUNT" --query "primaryEndpoints.web" -o tsv 2>/dev/null)
        local index_doc=$(echo "$website_info" | grep -o '"indexDocument":"[^"]*"' | cut -d'"' -f4)
        local error_doc=$(echo "$website_info" | grep -o '"errorDocument404Path":"[^"]*"' | cut -d'"' -f4)
        
        echo "Status: Enabled"
        echo "Website URL: $website_url"
        echo "Index Document: ${index_doc:-index.html}"
        if [ -n "$error_doc" ]; then
            echo "Error Document: $error_doc"
        fi
        echo ""
    else
        echo "=== Static Website Configuration ==="
        echo "Status: Disabled"
        echo ""
    fi
    
    echo "=== Blob Containers ==="
    local containers=$(az storage container list --account-name "$STORAGE_ACCOUNT" --query "[].{Name:name,PublicAccess:properties.publicAccess,LastModified:properties.lastModified}" -o table 2>/dev/null)
    if [ -n "$containers" ]; then
        echo "$containers"
    else
        echo "No containers found or unable to access containers."
    fi
    echo ""
    
    echo "=== Storage Usage ==="
    local usage=$(az storage account show-usage --location "$(az storage account show --name "$STORAGE_ACCOUNT" --query "location" -o tsv)" --query "{Used:currentValue,Limit:limit}" -o table 2>/dev/null)
    if [ -n "$usage" ]; then
        echo "$usage"
    else
        echo "Usage information not available."
    fi
}

function delete_storage() {
    local TARGET=""
    while [ -z "$TARGET" ]; do
        read -p "Enter storage account to DELETE FOREVER: " TARGET
        if [ -z "$TARGET" ]; then
            echo "Storage account name cannot be empty."
        fi
    done
    
    echo "Looking up storage account '$TARGET'..."
    local target_rg=$(az storage account show --name "$TARGET" --query "resourceGroup" -o tsv 2>/dev/null)
    
    if [ -z "$target_rg" ]; then
        echo "Storage account '$TARGET' not found in your subscription."
        return 1
    fi
    
    echo "Found storage account '$TARGET' in resource group '$target_rg'"
    echo "WARNING: This will permanently delete storage account '$TARGET' and all its data!"
    read -p "Type 'DELETE' to confirm: " CONFIRM
    
    if [ "$CONFIRM" != "DELETE" ]; then
        echo "Deletion cancelled."
        return 0
    fi
    
    echo "Deleting storage account $TARGET..."
    
    if ! az storage account delete \
        --name "$TARGET" \
        --resource-group "$target_rg" \
        --yes; then
        echo "Failed to delete storage account. Please check if you have permissions."
        return 1
    fi
    
    if [ "$STORAGE_ACCOUNT" = "$TARGET" ]; then
        STORAGE_ACCOUNT=""
    fi
}

function pick_storage_account() {
    echo "Available Storage Accounts:"
    local accounts=$(az storage account list --query "[].name" -o tsv 2>/dev/null)
    if [ -z "$accounts" ]; then
        echo "No storage accounts found in your subscription."
        return 1
    fi
    echo "$accounts"
    echo ""
    while [ -z "$STORAGE_ACCOUNT" ]; do
        read -p "Enter storage account name to use: " STORAGE_ACCOUNT
        if [ -z "$STORAGE_ACCOUNT" ]; then
            echo "Storage account name cannot be empty."
        fi
    done
}

function show_menu() {
    echo ""
    echo "1) Create new storage account"
    echo "2) Upload files"
    echo "3) Delete a blob"
    echo "4) List blobs"
    echo "5) Get storage account info"
    echo "6) Delete storage account"
    echo "7) Select a different storage account"
    echo "0) Exit"
}

while true; do
    show_menu
    read -p "Choose your chaos: " CHOICE

    case $CHOICE in
        1) create_storage ;;
        2) upload_files ;;
        3) delete_blob ;;
        4) list_blobs ;;
        5) get_storage_info ;;
        6) delete_storage ;;
        7) pick_storage_account ;;
        0) echo "Bye."; exit 0 ;;
        *) echo "Invalid option. Try reading next time." ;;
    esac
done

