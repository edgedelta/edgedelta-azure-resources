#!/bin/bash

# Integration Test - Full Deployment
# Deploys the template to Azure and validates outputs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"
TEMPLATE_FILE="$TEMPLATE_DIR/azuredeploy.json"
PARAM_FILE="${1:-$SCRIPT_DIR/parameters/test-all-new.json}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_RG="edgedelta-template-test-rg"
LOCATION="eastus"
DEPLOYMENT_NAME="test-deployment-$(date +%s)"

echo "=========================================="
echo "Integration Test - Full Deployment"
echo "=========================================="
echo ""
echo -e "${YELLOW}WARNING: This will deploy actual Azure resources${NC}"
echo "Resource Group: $TEST_RG"
echo "Location: $LOCATION"
echo "Parameter File: $PARAM_FILE"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Check Azure login
echo ""
echo "1. Checking Azure login..."
if ! az account show > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} Not logged into Azure. Run 'az login' first."
    exit 1
fi

ACCOUNT_NAME=$(az account show --query name -o tsv)
echo -e "${GREEN}✓${NC} Logged in as: $ACCOUNT_NAME"

# Create resource group
echo ""
echo "2. Creating/verifying resource group..."
if ! az group show --name "$TEST_RG" > /dev/null 2>&1; then
    echo "  Creating resource group: $TEST_RG"
    az group create --name "$TEST_RG" --location "$LOCATION" --output none
    echo -e "${GREEN}✓${NC} Resource group created"
else
    echo -e "${GREEN}✓${NC} Resource group exists"
fi

# Deploy template
echo ""
echo "3. Deploying ARM template..."
echo "  Deployment name: $DEPLOYMENT_NAME"
echo ""

DEPLOYMENT_OUTPUT=$(az deployment group create \
    --resource-group "$TEST_RG" \
    --name "$DEPLOYMENT_NAME" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "@$PARAM_FILE" \
    --output json)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Deployment successful"
else
    echo -e "${RED}✗${NC} Deployment failed"
    exit 1
fi

# Validate outputs
echo ""
echo "4. Validating deployment outputs..."

OUTPUTS=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs')

echo "  Checking required outputs..."
REQUIRED_OUTPUTS=("connectionString" "consumerGroup" "storageAccountName" "storageAccountKey" "storageContainerName")
for output in "${REQUIRED_OUTPUTS[@]}"; do
    VALUE=$(echo "$OUTPUTS" | jq -r ".$output.value")
    if [ -n "$VALUE" ] && [ "$VALUE" != "null" ]; then
        echo -e "${GREEN}✓${NC} $output: ${VALUE:0:50}..."
    else
        echo -e "${RED}✗${NC} $output: missing or null"
        exit 1
    fi
done

# Display summary
echo ""
echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
echo "$OUTPUTS" | jq -r 'to_entries[] | "\(.key): \(.value.value)"' | head -20

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Integration test passed!${NC}"
echo "=========================================="
echo ""
echo "Resources deployed successfully."
echo ""
echo "Next steps:"
echo "  - Verify resources in Azure Portal"
echo "  - Test Edge Delta integration with outputs"
echo "  - Run cleanup: ./tests/cleanup-test-resources.sh"
echo ""
