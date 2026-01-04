#!/bin/bash

set -e

RESOURCE_GROUP="rg-appservice-todo"

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
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed."
        exit 1
    fi
    
    if ! az account show &> /dev/null; then
        print_error "You are not logged in to Azure. Please run 'az login'"
        exit 1
    fi
}

delete_resource_group() {
    local rg_name=$1
    
    if ! az group show --name "$rg_name" &> /dev/null; then
        print_info "Resource group $rg_name does not exist"
        return
    fi
    
    print_info "Found resource group: $rg_name"
    print_warning "This will delete ALL resources in the resource group!"
    read -p "Type 'DELETE' to confirm: " CONFIRM
    
    if [ "$CONFIRM" = "DELETE" ]; then
        print_info "Deleting resource group: $rg_name"
        az group delete --name "$rg_name" --yes --no-wait
        print_info "Deletion initiated (running in background)"
    else
        print_info "Deletion cancelled"
    fi
}

list_resource_groups() {
    print_info "Listing all resource groups..."
    az group list --query "[].name" -o table
}

delete_all_resource_groups() {
    print_warning "WARNING: This will delete ALL resource groups in your subscription!"
    read -p "Type 'DELETE ALL' to confirm: " CONFIRM
    
    if [ "$CONFIRM" != "DELETE ALL" ]; then
        print_info "Deletion cancelled"
        return
    fi
    
    local rgs=$(az group list --query "[].name" -o tsv)
    
    if [ -z "$rgs" ]; then
        print_info "No resource groups found"
        return
    fi
    
    for rg in $rgs; do
        print_info "Deleting resource group: $rg"
        az group delete --name "$rg" --yes --no-wait
    done
    
    print_info "Deletion initiated for all resource groups (running in background)"
}

show_menu() {
    echo ""
    echo "Azure Resources Cleanup"
    echo "======================"
    echo ""
    echo "1) Delete project resource group ($RESOURCE_GROUP)"
    echo "2) List all resource groups"
    echo "3) Delete ALL resource groups (DANGEROUS!)"
    echo "4) Delete specific resource group by name"
    echo "0) Exit"
    echo ""
}

main() {
    check_prerequisites
    
    if [ $# -eq 0 ]; then
        while true; do
            show_menu
            read -p "Choose an option: " CHOICE
            
            case $CHOICE in
                1) delete_resource_group "$RESOURCE_GROUP" ;;
                2) list_resource_groups ;;
                3) delete_all_resource_groups ;;
                4)
                    read -p "Enter resource group name: " RG_NAME
                    delete_resource_group "$RG_NAME"
                    ;;
                0)
                    print_info "Exiting..."
                    exit 0
                    ;;
                *)
                    print_error "Invalid option"
                    ;;
            esac
        done
    else
        case $1 in
            --project|-p) delete_resource_group "$RESOURCE_GROUP" ;;
            --list|-l) list_resource_groups ;;
            --all|-a) delete_all_resource_groups ;;
            --help|-h)
                echo "Usage: $0 [OPTION]"
                echo ""
                echo "Options:"
                echo "  -p, --project    Delete project resource group"
                echo "  -l, --list       List all resource groups"
                echo "  -a, --all        Delete ALL resource groups (DANGEROUS!)"
                echo "  -h, --help       Show this help"
                echo ""
                echo "If no option is provided, interactive menu will be shown."
                ;;
            *)
                if [ -n "$1" ]; then
                    delete_resource_group "$1"
                else
                    print_error "Invalid option. Use --help for usage."
                    exit 1
                fi
                ;;
        esac
    fi
}

main "$@"
