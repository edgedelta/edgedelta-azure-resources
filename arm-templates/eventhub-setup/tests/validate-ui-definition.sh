#!/bin/bash

# UI Definition Validation Script
# Tests createUiDefinition.json syntax and provides sandbox URL

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPT_DIR")"
UI_FILE="$TEMPLATE_DIR/createUiDefinition.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "UI Definition Validation"
echo "=========================================="
echo ""

# Test JSON syntax
echo "1. Validating JSON syntax..."
if command -v jq &> /dev/null; then
    if jq empty "$UI_FILE" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} UI definition JSON is valid"
    else
        echo -e "${RED}✗${NC} UI definition JSON is invalid"
        exit 1
    fi
else
    echo -e "${RED}✗${NC} jq not installed. Install with: brew install jq"
    exit 1
fi

# Browser-based sandbox testing
echo ""
echo "=========================================="
echo "Interactive UI Definition Testing"
echo "=========================================="
echo ""
echo -e "${BLUE}To test the UI definition interactively:${NC}"
echo ""
echo "1. Open the Azure Portal UI Definition Sandbox:"
echo "   https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade"
echo ""
echo "2. Load the UI definition file:"
echo "   $UI_FILE"
echo ""
echo "3. Test these scenarios:"
echo "   ✓ All dropdowns populate correctly"
echo "   ✓ Resource selectors show existing resources"
echo "   ✓ Default values are set properly"
echo "   ✓ Validation messages appear correctly"
echo "   ✓ Outputs match template parameters"
echo ""
echo "=========================================="

echo ""
echo -e "${GREEN}✓ UI definition validation passed!${NC}"
echo ""
