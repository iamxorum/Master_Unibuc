#!/bin/bash

set -e

RESOURCE_GROUP="rg-appservice-todo"
LOCATION="spaincentral"
APP_SERVICE_PLAN="asp-todo-app"
APP_SERVICE_NAME="todo-app"
SQL_SERVER_NAME="sql-todo"
SQL_DATABASE_NAME="tododb"
SQL_ADMIN_USER="sqladmin"
SQL_ADMIN_PASSWORD="portocala12!$"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it from https://aka.ms/InstallAzureCLI"
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        print_error "You are not logged in to Azure. Please run 'az login'"
        exit 1
    fi
    
    print_info "Prerequisites check passed"
}

generate_names() {
    if [ -z "$APP_SERVICE_NAME" ]; then
        APP_SERVICE_NAME="app-todo-$(openssl rand -hex 3)"
    else
        APP_SERVICE_NAME="${APP_SERVICE_NAME}-$(openssl rand -hex 3)"
    fi
    
    if [ -z "$SQL_SERVER_NAME" ]; then
        SQL_SERVER_NAME="sql-todo-$(openssl rand -hex 3)"
    else
        SQL_SERVER_NAME="${SQL_SERVER_NAME}-$(openssl rand -hex 3)"
    fi
    
    if [ -z "$SQL_ADMIN_PASSWORD" ]; then
        SQL_ADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    fi
    
    print_info "Generated names:"
    print_info "  App Service: $APP_SERVICE_NAME"
    print_info "  SQL Server: $SQL_SERVER_NAME"
    print_info "  SQL Database: $SQL_DATABASE_NAME"
}

create_resources() {
    print_info "Step 1: Creating Azure resources..."
    
    RG_STATUS=$(az group show --name "$RESOURCE_GROUP" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "NotFound")
    
    if [ "$RG_STATUS" = "Deleting" ]; then
        print_warning "Resource group is being deleted. Waiting..."
        while [ "$RG_STATUS" = "Deleting" ]; do
            sleep 10
            RG_STATUS=$(az group show --name "$RESOURCE_GROUP" --query "properties.provisioningState" -o tsv 2>/dev/null || echo "NotFound")
        done
    fi
    
    if [ "$RG_STATUS" = "NotFound" ]; then
        print_info "Creating resource group: $RESOURCE_GROUP"
        az group create --name "$RESOURCE_GROUP" --location "$LOCATION" > /dev/null
    else
        print_info "Using existing resource group: $RESOURCE_GROUP"
    fi
    
    if ! az appservice plan show --name "$APP_SERVICE_PLAN" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        print_info "Creating App Service Plan: $APP_SERVICE_PLAN"
        az appservice plan create \
            --name "$APP_SERVICE_PLAN" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku B1 \
            --is-linux > /dev/null 2>&1
    fi
    
    if ! az webapp show --name "$APP_SERVICE_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        print_info "Creating App Service: $APP_SERVICE_NAME"
        az webapp create \
            --name "$APP_SERVICE_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --plan "$APP_SERVICE_PLAN" \
            --runtime "NODE:20-lts" > /dev/null 2>&1
    fi
    
    if ! az sql server show --name "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        print_info "Creating SQL Server: $SQL_SERVER_NAME"
        az sql server create \
            --name "$SQL_SERVER_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --admin-user "$SQL_ADMIN_USER" \
            --admin-password "$SQL_ADMIN_PASSWORD" > /dev/null
    fi
    
    print_info "Configuring SQL Server firewall..."
    az sql server firewall-rule delete \
        --resource-group "$RESOURCE_GROUP" \
        --server "$SQL_SERVER_NAME" \
        --name "AllowAllWindowsAzureIps" > /dev/null 2>&1 || true
    
    OUTBOUND_IPS=$(az webapp show \
        --name "$APP_SERVICE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "outboundIpAddresses" -o tsv)
    
    IFS=',' read -ra IPS <<< "$OUTBOUND_IPS"
    for ip in "${IPS[@]}"; do
        ip=$(echo "$ip" | xargs)
        if [ -n "$ip" ]; then
            az sql server firewall-rule create \
                --resource-group "$RESOURCE_GROUP" \
                --server "$SQL_SERVER_NAME" \
                --name "AppService-$(echo $ip | tr '.' '-')" \
                --start-ip-address "$ip" \
                --end-ip-address "$ip" > /dev/null 2>&1 || true
        fi
    done
    
    if ! az sql db show --name "$SQL_DATABASE_NAME" --server "$SQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        print_info "Creating SQL Database: $SQL_DATABASE_NAME"
        az sql db create \
            --resource-group "$RESOURCE_GROUP" \
            --server "$SQL_SERVER_NAME" \
            --name "$SQL_DATABASE_NAME" \
            --service-objective Basic > /dev/null
    fi
    
    print_info "Resources created successfully"
}

configure_app_settings() {
    print_info "Step 2: Configuring application settings..."
    
    az webapp config appsettings set \
        --name "$APP_SERVICE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --settings \
            "DB_SERVER=${SQL_SERVER_NAME}.database.windows.net" \
            "DB_NAME=$SQL_DATABASE_NAME" \
            "DB_USER=$SQL_ADMIN_USER" \
            "DB_PASSWORD=$SQL_ADMIN_PASSWORD" \
            "PORT=8080" \
            "SCM_DO_BUILD_DURING_DEPLOYMENT=true" > /dev/null
    
    az webapp config set \
        --name "$APP_SERVICE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --startup-file "npm start" \
        --linux-fx-version "NODE|20-lts" > /dev/null
    
    print_info "Application settings configured"
}

initialize_database() {
    print_info "Step 3: Initializing database schema..."
    sleep 10
    
    if command -v sqlcmd &> /dev/null; then
        print_info "Using sqlcmd to initialize database..."
        sqlcmd -S "${SQL_SERVER_NAME}.database.windows.net" \
            -d "$SQL_DATABASE_NAME" \
            -U "$SQL_ADMIN_USER" \
            -P "$SQL_ADMIN_PASSWORD" \
            -i database/init.sql
    else
        print_warning "sqlcmd not found. Database will be initialized on first app start."
    fi
}

deploy_application() {
    print_info "Step 4: Deploying application code..."
    
    ZIP_FILE="deploy.zip"
    TEMP_DIR=$(mktemp -d)
    
    cp -r public "$TEMP_DIR/"
    cp server.js package.json "$TEMP_DIR/"
    [ -f ".deployment" ] && cp .deployment "$TEMP_DIR/"
    [ -d "database" ] && cp -r database "$TEMP_DIR/"
    
    cd "$TEMP_DIR"
    zip -r "$OLDPWD/$ZIP_FILE" . > /dev/null 2>&1
    cd "$OLDPWD"
    rm -rf "$TEMP_DIR"
    
    print_info "Uploading application to App Service..."
    az webapp deployment source config-zip \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_SERVICE_NAME" \
        --src "$ZIP_FILE" > /dev/null
    
    rm -f "$ZIP_FILE"
    sleep 5
    
    print_info "Restarting application..."
    az webapp restart \
        --name "$APP_SERVICE_NAME" \
        --resource-group "$RESOURCE_GROUP" > /dev/null
    
    print_info "Application deployed successfully"
}

display_info() {
    print_info "Step 5: Deployment Summary"
    echo ""
    echo "=========================================="
    echo "  Deployment Complete!"
    echo "=========================================="
    echo ""
    echo "Resource Group: $RESOURCE_GROUP"
    echo "App Service: $APP_SERVICE_NAME"
    echo "SQL Server: $SQL_SERVER_NAME"
    echo "SQL Database: $SQL_DATABASE_NAME"
    echo ""
    echo "Application URL:"
    APP_URL=$(az webapp show \
        --name "$APP_SERVICE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "defaultHostName" -o tsv)
    echo "  https://$APP_URL"
    echo ""
    echo "SQL Server Connection:"
    echo "  Server: ${SQL_SERVER_NAME}.database.windows.net"
    echo "  Database: $SQL_DATABASE_NAME"
    echo "  Username: $SQL_ADMIN_USER"
    echo "  Password: $SQL_ADMIN_PASSWORD"
    echo ""
    echo "=========================================="
    echo ""
    print_warning "Note: The database is secured and only accessible from the App Service."
    print_info "The application may take 1-2 minutes to start. Please wait before accessing."
}

main() {
    print_info "Starting Azure App Service deployment..."
    echo ""
    
    check_prerequisites
    generate_names
    echo ""
    
    create_resources
    configure_app_settings
    initialize_database
    deploy_application
    echo ""
    display_info
}

main
