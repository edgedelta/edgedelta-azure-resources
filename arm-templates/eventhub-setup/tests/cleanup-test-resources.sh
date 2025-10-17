#!/bin/bash

# Cleanup Test Resources
# Deletes the test resource group and all resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TEST_RG="edgedelta-template-test-rg"

echo "=========================================="
echo "Cleanup Test Resources"
echo "=========================================="
echo ""
echo -e "${YELLOW}WARNING: This will delete the resource group:${NC}"
echo "  $TEST_RG"
echo ""
echo "This will permanently delete all resources in this group."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Checking if resource group exists..."

if az group show --name "$TEST_RG" > /dev/null 2>&1; then
    echo "Found resource group: $TEST_RG"
    echo ""
    echo "Resources in this group:"
    az resource list --resource-group "$TEST_RG" --query "[].{Name:name, Type:type}" -o table
    echo ""
    echo "Deleting resource group..."
    az group delete --name "$TEST_RG" --yes --no-wait
    echo -e "${GREEN}✓${NC} Deletion initiated (running in background)"
    echo ""
    echo "Monitor deletion status with:"
    echo "  az group show --name $TEST_RG"
else
    echo -e "${YELLOW}⚠${NC} Resource group not found: $TEST_RG"
    echo "Nothing to clean up."
fi

echo ""
echo "Cleanup complete."
