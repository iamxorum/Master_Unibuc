#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLEANUP_SCRIPT="$SCRIPT_DIR/cleanup.sh"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

show_menu() {
    clear
    print_header "Azure Todo App - Management"
    echo "1) Deploy application"
    echo "2) Cleanup resources"
    echo "3) Redeploy (cleanup + deploy)"
    echo "0) Exit"
    echo ""
}

main() {
    if [ ! -f "$CLEANUP_SCRIPT" ] || [ ! -f "$DEPLOY_SCRIPT" ]; then
        print_error "Required scripts not found!"
        exit 1
    fi

    chmod +x "$CLEANUP_SCRIPT" "$DEPLOY_SCRIPT" 2>/dev/null || true

    if [ $# -gt 0 ]; then
        case "$1" in
            deploy|d)
                print_header "Deploying Application"
                "$DEPLOY_SCRIPT"
                ;;
            cleanup|c)
                print_header "Cleaning Up Resources"
                "$CLEANUP_SCRIPT" "$@"
                ;;
            redeploy|r)
                print_header "Redeploying Application"
                print_warning "This will delete existing resources and redeploy"
                read -p "Continue? (y/N): " CONFIRM
                if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
                    "$CLEANUP_SCRIPT" --project
                    echo ""
                    sleep 5
                    "$DEPLOY_SCRIPT"
                else
                    print_info "Cancelled"
                fi
                ;;
            help|-h|--help)
                echo "Usage: $0 [COMMAND]"
                echo ""
                echo "Commands:"
                echo "  deploy, d      Deploy the application"
                echo "  cleanup, c     Clean up Azure resources"
                echo "  redeploy, r    Clean up and redeploy"
                echo "  help, -h       Show this help"
                echo ""
                echo "If no command is provided, interactive menu will be shown."
                ;;
            *)
                print_error "Unknown command: $1"
                echo "Use '$0 help' for usage information"
                exit 1
                ;;
        esac
    else
        while true; do
            show_menu
            read -p "Choose an option: " CHOICE
            
            case $CHOICE in
                1)
                    print_header "Deploying Application"
                    "$DEPLOY_SCRIPT"
                    echo ""
                    read -p "Press Enter to continue..."
                    ;;
                2)
                    print_header "Cleaning Up Resources"
                    "$CLEANUP_SCRIPT"
                    echo ""
                    read -p "Press Enter to continue..."
                    ;;
                3)
                    print_header "Redeploying Application"
                    print_warning "This will delete existing resources and redeploy"
                    read -p "Continue? (y/N): " CONFIRM
                    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
                        "$CLEANUP_SCRIPT" --project
                        echo ""
                        sleep 5
                        "$DEPLOY_SCRIPT"
                    else
                        print_info "Cancelled"
                    fi
                    echo ""
                    read -p "Press Enter to continue..."
                    ;;
                0)
                    print_info "Exiting..."
                    exit 0
                    ;;
                *)
                    print_error "Invalid option"
                    sleep 2
                    ;;
            esac
        done
    fi
}

main "$@"

