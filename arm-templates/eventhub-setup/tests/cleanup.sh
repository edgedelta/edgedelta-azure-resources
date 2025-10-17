#!/bin/bash

# Cleanup Script for Edge Delta Event Hub ARM Template Deployments
#
# ⚠️  WARNING: FOR LOCAL DEVELOPMENT AND TESTING ONLY
#
# This script helps clean up failed or test deployments by removing:
# - Subscription-level diagnostic settings
# - Event Hub resources
# - Storage accounts
# - Deployments
#
# USE WITH CAUTION: This script deletes resources and cannot be undone.
# Always review what will be deleted before confirming.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Banner
echo ""
echo -e "${RED}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}${BOLD}║                                                            ║${NC}"
echo -e "${RED}${BOLD}║         ⚠️  CLEANUP SCRIPT - USE WITH CAUTION ⚠️           ║${NC}"
echo -e "${RED}${BOLD}║                                                            ║${NC}"
echo -e "${RED}${BOLD}║    FOR LOCAL DEVELOPMENT AND TESTING ONLY                  ║${NC}"
echo -e "${RED}${BOLD}║                                                            ║${NC}"
echo -e "${RED}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This script will DELETE Azure resources. This action CANNOT be undone.${NC}"
echo ""

# Check prerequisites
if ! command -v az &> /dev/null; then
    echo -e "${RED}✗${NC} Azure CLI not installed"
    exit 1
fi

if ! az account show > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} Not logged into Azure"
    echo "  Run 'az login' to authenticate"
    exit 1
fi

echo -e "${GREEN}✓${NC} Connected to Azure"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo "  Subscription: $SUBSCRIPTION_NAME"
echo "  ID: $SUBSCRIPTION_ID"
echo ""

# Menu
echo "What would you like to clean up?"
echo ""
echo "  1) List all diagnostic settings (subscription-level)"
echo "  2) Delete diagnostic settings by pattern"
echo "  3) Clean up test deployment resources"
echo "  4) List all deployments"
echo "  5) Exit"
echo ""
read -p "Choose an option (1-5): " OPTION

case $OPTION in
    1)
        echo ""
        echo "=========================================="
        echo "Subscription Diagnostic Settings"
        echo "=========================================="
        echo ""
        az monitor diagnostic-settings subscription list --output table || echo "No diagnostic settings found"
        ;;
    2)
        echo ""
        read -p "Enter pattern to match (e.g., 'edgedelta-activity-logs'): " PATTERN
        echo ""
        echo "Searching for diagnostic settings matching: $PATTERN"
        echo ""

        SETTINGS=$(az monitor diagnostic-settings subscription list --query "[?contains(name, '$PATTERN')].name" -o tsv)

        if [ -z "$SETTINGS" ]; then
            echo "No diagnostic settings found matching '$PATTERN'"
            exit 0
        fi

        echo "Found diagnostic settings:"
        echo "$SETTINGS"
        echo ""
        echo -e "${RED}${BOLD}WARNING: This will DELETE the above diagnostic settings.${NC}"
        read -p "Are you sure? Type 'yes' to confirm: " CONFIRM

        if [ "$CONFIRM" = "yes" ]; then
            while IFS= read -r SETTING; do
                echo "Deleting: $SETTING"
                az monitor diagnostic-settings subscription delete --name "$SETTING" --yes
                echo -e "${GREEN}✓${NC} Deleted: $SETTING"
            done <<< "$SETTINGS"
            echo ""
            echo -e "${GREEN}Cleanup complete!${NC}"
        else
            echo "Cancelled."
        fi
        ;;
    3)
        echo ""
        read -p "Resource group name: " RESOURCE_GROUP

        if ! az group show --name "$RESOURCE_GROUP" > /dev/null 2>&1; then
            echo -e "${RED}✗${NC} Resource group not found: $RESOURCE_GROUP"
            exit 1
        fi

        echo ""
        echo "Resources in $RESOURCE_GROUP:"
        echo ""
        az resource list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, Type:type}" -o table
        echo ""
        echo -e "${RED}${BOLD}WARNING: This will DELETE the entire resource group and ALL resources in it.${NC}"
        read -p "Are you sure you want to delete resource group '$RESOURCE_GROUP'? Type 'DELETE' to confirm: " CONFIRM

        if [ "$CONFIRM" = "DELETE" ]; then
            echo "Deleting resource group: $RESOURCE_GROUP"
            az group delete --name "$RESOURCE_GROUP" --yes --no-wait
            echo -e "${GREEN}✓${NC} Deletion initiated (running in background)"
            echo "  Check status: az group show --name '$RESOURCE_GROUP'"
        else
            echo "Cancelled."
        fi
        ;;
    4)
        echo ""
        echo "=========================================="
        echo "Recent Subscription Deployments"
        echo "=========================================="
        echo ""
        az deployment sub list --query "[?properties.timestamp>'2025-01-01'].{Name:name, Status:properties.provisioningState, Timestamp:properties.timestamp}" -o table | head -20
        echo ""
        read -p "Delete a deployment? (y/n): " DELETE_DEPLOY
        if [ "$DELETE_DEPLOY" = "y" ]; then
            read -p "Deployment name: " DEPLOY_NAME
            echo "Deleting deployment: $DEPLOY_NAME"
            az deployment sub delete --name "$DEPLOY_NAME"
            echo -e "${GREEN}✓${NC} Deleted deployment"
        fi
        ;;
    5)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac

echo ""
