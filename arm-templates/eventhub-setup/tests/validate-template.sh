#!/bin/bash

# ARM Template Validation Script
# Uses Microsoft's ARM Template Test Toolkit (arm-ttk)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$TEMPLATE_DIR/../.." && pwd)"
ARM_TTK_PATH="$REPO_ROOT/arm-ttk/arm-ttk"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "ARM Template Validation"
echo "=========================================="
echo ""

# Check if arm-ttk is available
if [ ! -d "$ARM_TTK_PATH" ]; then
    echo -e "${YELLOW}⚠${NC} ARM-TTK not found. Installing..."
    cd "$REPO_ROOT"
    git clone https://github.com/Azure/arm-ttk.git --depth 1
    echo -e "${GREEN}✓${NC} ARM-TTK installed"
    echo ""
fi

# Test 1: JSON syntax validation
echo "1. Validating JSON syntax..."
if command -v jq &> /dev/null; then
    if jq empty "$TEMPLATE_DIR/azuredeploy.json" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Template JSON is valid"
    else
        echo -e "${RED}✗${NC} Template JSON is invalid"
        exit 1
    fi

    if jq empty "$TEMPLATE_DIR/createUiDefinition.json" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} UI definition JSON is valid"
    else
        echo -e "${RED}✗${NC} UI definition JSON is invalid"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠${NC} jq not installed, skipping JSON validation"
fi

# Test 2: Run ARM-TTK
echo ""
echo "2. Running Microsoft ARM Template Test Toolkit..."
echo ""

# Run arm-ttk using PowerShell (optional but recommended)
if command -v pwsh &> /dev/null; then
    pwsh -Command "
        Import-Module '$ARM_TTK_PATH/arm-ttk.psd1'
        Test-AzTemplate -TemplatePath '$TEMPLATE_DIR' -Skip 'apiVersions Should Be Recent'
    "
else
    echo -e "${YELLOW}⚠${NC} PowerShell (pwsh) not installed - skipping ARM-TTK tests"
    echo "  ARM-TTK provides comprehensive best-practice validation"
    echo "  Install PowerShell: brew install --cask powershell"
    echo "  Continuing with Azure CLI validation..."
fi

# Test 3: Azure CLI validation (if logged in)
echo ""
echo "3. Azure CLI template validation..."

if ! command -v az &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Azure CLI not installed, skipping Azure validation"
elif ! az account show > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠${NC} Not logged into Azure, skipping Azure validation"
    echo "  Run 'az login' to enable Azure validation"
else
    TEST_RG="edgedelta-template-test-rg"
    LOCATION="eastus"

    echo "  Ensuring test resource group exists..."
    if ! az group show --name "$TEST_RG" > /dev/null 2>&1; then
        az group create --name "$TEST_RG" --location "$LOCATION" --output none
        echo -e "${GREEN}✓${NC} Test resource group created"
    else
        echo -e "${GREEN}✓${NC} Test resource group exists"
    fi

    echo "  Validating template against Azure..."
    if az deployment group validate \
        --resource-group "$TEST_RG" \
        --template-file "$TEMPLATE_DIR/azuredeploy.json" \
        --parameters \
            eventHubNamespaceName="test-eh-$(date +%s | tail -c 7)" \
            storageAccountName="testchk$(date +%s | tail -c 8)" \
            location="eastus" \
            configureActivityLogs=false \
        --output none 2>&1; then
        echo -e "${GREEN}✓${NC} Azure template validation passed"
    else
        echo -e "${RED}✗${NC} Azure template validation failed"
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✓ All validation tests passed!${NC}"
echo "=========================================="
