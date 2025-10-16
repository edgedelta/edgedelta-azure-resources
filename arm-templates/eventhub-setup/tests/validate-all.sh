#!/bin/bash

# Main Test Runner
# Runs all validation tests for ARM template and UI definition

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "=========================================="
echo "Edge Delta Azure Event Hub ARM Template"
echo "Complete Validation Suite"
echo "=========================================="
echo ""

# Run template validation
echo -e "${BLUE}Running ARM Template Validation...${NC}"
echo ""
bash "$SCRIPT_DIR/validate-template.sh"

echo ""
echo ""

# Run UI definition validation
echo -e "${BLUE}Running UI Definition Validation...${NC}"
echo ""
bash "$SCRIPT_DIR/validate-ui-definition.sh"

echo ""
echo ""
echo "=========================================="
echo -e "${GREEN}✓ All validation tests passed!${NC}"
echo "=========================================="
echo ""
echo "Template is ready for deployment."
echo ""
