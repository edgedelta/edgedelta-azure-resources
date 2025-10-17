#!/bin/bash

# What-If Deployment Test Script
# Tests ARM template deployment without making any changes
# Use this to preview what resources will be created/modified

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=========================================="
echo "ARM Template What-If Deployment Test"
echo "=========================================="
echo ""

# Check prerequisites
if ! command -v az &> /dev/null; then
    echo -e "${RED}✗${NC} Azure CLI not installed"
    echo "  Install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

if ! az account show > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} Not logged into Azure"
    echo "  Run 'az login' to authenticate"
    exit 1
fi

echo -e "${GREEN}✓${NC} Prerequisites met"
echo ""

# Get parameters from user
read -p "Resource group name (must exist): " RESOURCE_GROUP
read -p "Event Hub namespace name (globally unique): " NAMESPACE_NAME
read -p "Storage account name (globally unique, 3-24 lowercase alphanumeric): " STORAGE_NAME
read -p "Location (default: eastus): " LOCATION
LOCATION=${LOCATION:-eastus}

# Verify resource group exists
echo ""
echo "Verifying resource group exists..."
if ! az group show --name "$RESOURCE_GROUP" > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} Resource group '$RESOURCE_GROUP' does not exist"
    echo "  Create it first: az group create --name '$RESOURCE_GROUP' --location '$LOCATION'"
    exit 1
fi
echo -e "${GREEN}✓${NC} Resource group exists"
echo ""

# Run what-if deployment
echo "=========================================="
echo "Running What-If Analysis..."
echo "=========================================="
echo ""
echo "This will show you what resources would be created/modified WITHOUT actually deploying anything."
echo ""

az deployment sub what-if \
    --location "$LOCATION" \
    --template-file "$TEMPLATE_DIR/azuredeploy.json" \
    --parameters \
        resourceGroupName="$RESOURCE_GROUP" \
        eventHubNamespaceName="$NAMESPACE_NAME" \
        storageAccountName="$STORAGE_NAME" \
        location="$LOCATION" \
        configureActivityLogs=false

echo ""
echo "=========================================="
echo "What-If Analysis Complete"
echo "=========================================="
echo ""
echo "Review the output above to see what would be deployed."
echo "If everything looks correct, proceed with actual deployment."
echo ""
