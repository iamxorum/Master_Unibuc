#!/bin/bash

set -e

# Configuration
RESOURCE_GROUP="rg-openai-plugin"
LOCATION="swedencentral"
APP_SERVICE_PLAN="asp-grammar-plugin"
APP_SERVICE_NAME="grammar-plugin"
OPENAI_ACCOUNT_NAME="openai-grammar"
OPENAI_DEPLOYMENT_NAME="gpt-4o-mini"
OPENAI_MODEL_NAME="gpt-4o-mini"

# Colors for output
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
    SUFFIX=$(openssl rand -hex 3)
    
    APP_SERVICE_NAME="${APP_SERVICE_NAME}-${SUFFIX}"
    OPENAI_ACCOUNT_NAME="${OPENAI_ACCOUNT_NAME}-${SUFFIX}"
    
    print_info "Generated names:"
    print_info "  App Service: $APP_SERVICE_NAME"
    print_info "  OpenAI Account: $OPENAI_ACCOUNT_NAME"
}

create_resource_group() {
    print_info "Step 1: Creating Resource Group..."
    
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
}

create_openai_resource() {
    print_info "Step 2: Creating Azure OpenAI resource..."
    
    # Check if OpenAI account already exists
    if ! az cognitiveservices account show --name "$OPENAI_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        print_info "Creating Azure OpenAI account: $OPENAI_ACCOUNT_NAME"
        az cognitiveservices account create \
            --name "$OPENAI_ACCOUNT_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --kind "OpenAI" \
            --sku "S0" \
            --custom-domain "$OPENAI_ACCOUNT_NAME" > /dev/null
        
        print_info "Waiting for OpenAI account to be ready..."
        sleep 30
    else
        print_info "Using existing OpenAI account: $OPENAI_ACCOUNT_NAME"
    fi
    
    # Get openAI endpoint
    OPENAI_ENDPOINT=$(az cognitiveservices account show \
        --name "$OPENAI_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "properties.endpoint" -o tsv)
    
    OPENAI_API_KEY=$(az cognitiveservices account keys list \
        --name "$OPENAI_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "key1" -o tsv)
    
    print_info "OpenAI endpoint: $OPENAI_ENDPOINT"
}

deploy_openai_model() {
    print_info "Step 3: Deploying OpenAI model..."
    
    # Check if it is already deployed
    DEPLOYMENT_EXISTS=$(az cognitiveservices account deployment list \
        --name "$OPENAI_ACCOUNT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "[?name=='$OPENAI_DEPLOYMENT_NAME'].name" -o tsv 2>/dev/null || echo "")
    
    if [ -z "$DEPLOYMENT_EXISTS" ]; then
        print_info "Creating model deployment: $OPENAI_DEPLOYMENT_NAME"
        az cognitiveservices account deployment create \
            --name "$OPENAI_ACCOUNT_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --deployment-name "$OPENAI_DEPLOYMENT_NAME" \
            --model-name "$OPENAI_MODEL_NAME" \
            --model-version "2024-07-18" \
            --model-format "OpenAI" \
            --sku-capacity 10 \
            --sku-name "GlobalStandard" > /dev/null
        
        print_info "Waiting for model deployment to be ready..."
        sleep 30
    else
        print_info "Using existing deployment: $OPENAI_DEPLOYMENT_NAME"
    fi
}

create_app_service() {
    print_info "Step 4: Creating App Service..."
    
    # create app service plan
    if ! az appservice plan show --name "$APP_SERVICE_PLAN" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        print_info "Creating App Service Plan: $APP_SERVICE_PLAN"
        az appservice plan create \
            --name "$APP_SERVICE_PLAN" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku B1 \
            --is-linux > /dev/null 2>&1
    else
        print_info "Using existing App Service Plan: $APP_SERVICE_PLAN"
    fi
    
    # App Service
    if ! az webapp show --name "$APP_SERVICE_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        print_info "Creating App Service: $APP_SERVICE_NAME"
        az webapp create \
            --name "$APP_SERVICE_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --plan "$APP_SERVICE_PLAN" \
            --runtime "NODE:20-lts" > /dev/null 2>&1
    else
        print_info "Using existing App Service: $APP_SERVICE_NAME"
    fi
}

configure_app_settings() {
    print_info "Step 5: Configuring application settings..."
    
    az webapp config appsettings set \
        --name "$APP_SERVICE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --settings \
            "AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT" \
            "AZURE_OPENAI_API_KEY=$OPENAI_API_KEY" \
            "AZURE_OPENAI_DEPLOYMENT_NAME=$OPENAI_DEPLOYMENT_NAME" \
            "PORT=8080" \
            "SCM_DO_BUILD_DURING_DEPLOYMENT=true" > /dev/null
    
    az webapp config set \
        --name "$APP_SERVICE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --startup-file "npm start" \
        --linux-fx-version "NODE|20-lts" > /dev/null
    
    print_info "Application settings configured"
}

deploy_application() {
    print_info "Step 6: Deploying application code..."
    
    ZIP_FILE="deploy.zip"
    TEMP_DIR=$(mktemp -d)

    cp -r public "$TEMP_DIR/"
    cp server.js package.json "$TEMP_DIR/"
    [ -f ".deployment" ] && cp .deployment "$TEMP_DIR/"
    
    cd "$TEMP_DIR"
    zip -r "$OLDPWD/$ZIP_FILE" . > /dev/null 2>&1
    cd "$OLDPWD"
    rm -rf "$TEMP_DIR"
    
    # deploy
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
    print_info "Step 7: Deployment Summary"
    echo ""
    echo "=========================================="
    echo "  Deployment Complete!"
    echo "=========================================="
    echo ""
    echo "Resource Group: $RESOURCE_GROUP"
    echo "App Service: $APP_SERVICE_NAME"
    echo "OpenAI Account: $OPENAI_ACCOUNT_NAME"
    echo "OpenAI Deployment: $OPENAI_DEPLOYMENT_NAME"
    echo ""
    echo "Application URL:"
    APP_URL=$(az webapp show \
        --name "$APP_SERVICE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "defaultHostName" -o tsv)
    echo "  https://$APP_URL"
    echo ""
    echo "API Endpoints:"
    echo "  GET  https://$APP_URL/info"
    echo "  POST https://$APP_URL/prompt"
    echo ""
    echo "Azure OpenAI Configuration:"
    echo "  Endpoint: $OPENAI_ENDPOINT"
    echo "  Deployment: $OPENAI_DEPLOYMENT_NAME"
    echo "  Model: $OPENAI_MODEL_NAME"
    echo ""
    echo "=========================================="
    echo ""
    echo ""
    echo "  curl https://$APP_URL/info"
    echo ""
    echo "  curl -X POST https://$APP_URL/prompt \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{\"prompt\": \"Am mers avut pana in brutarie.\"}'"
    echo ""
}

main() {
    print_info "Starting Azure OpenAI Plugin deployment..."
    echo ""
    
    check_prerequisites
    generate_names
    echo ""
    
    create_resource_group
    create_openai_resource
    deploy_openai_model
    create_app_service
    configure_app_settings
    deploy_application
    echo ""
    display_info
}

main
