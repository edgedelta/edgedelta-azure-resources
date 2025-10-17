#!/bin/bash

# Git Hooks Installation Script
# Installs pre-commit hook to automatically validate ARM templates

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$REPO_ROOT/.githooks"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"

echo "=========================================="
echo "Installing Git Hooks"
echo "=========================================="
echo ""

# Method 1: Use git config to point to .githooks directory (Git 2.9+)
echo "Configuring Git to use .githooks directory..."
git config core.hooksPath .githooks
echo "✓ Git configured to use .githooks"

# Make hooks executable
echo ""
echo "Making hooks executable..."
chmod +x "$HOOKS_DIR/pre-commit"
echo "✓ Hooks are executable"

echo ""
echo "=========================================="
echo "✓ Git hooks installed successfully!"
echo "=========================================="
echo ""
echo "The pre-commit hook will now run automatically before each commit."
echo ""
echo "What it does:"
echo "  - Detects ARM template changes"
echo "  - Runs validation tests"
echo "  - Prevents commit if validation fails"
echo ""
echo "To bypass the hook (not recommended):"
echo "  git commit --no-verify"
echo ""
