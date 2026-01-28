#!/bin/bash

set -e

RESOURCE_GROUP="rg-openai-plugin"

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

echo ""
echo "=========================================="
echo "  Azure OpenAI Plugin Cleanup Script"
echo "=========================================="
echo ""

print_warning "This will delete the resource group '$RESOURCE_GROUP' and ALL resources within it."
print_warning "This action cannot be undone!"
echo ""

read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "Cleanup cancelled."
    exit 0
fi

echo ""

# Check if resource group exists
if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    print_info "Deleting resource group: $RESOURCE_GROUP"
    print_info "This may take a few minutes..."
    
    az group delete --name "$RESOURCE_GROUP" --yes --no-wait
    
    print_info "Deletion initiated. The resource group is being deleted in the background."
    print_info "You can check the status in the Azure Portal."
else
    print_warning "Resource group '$RESOURCE_GROUP' does not exist."
fi

echo ""
print_info "Cleanup complete!"
