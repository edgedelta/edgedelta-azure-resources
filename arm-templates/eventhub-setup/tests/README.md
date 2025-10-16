# ARM Template Testing

Comprehensive test suite for the Edge Delta Azure Event Hub ARM template.

## Test Structure

```
tests/
├── validate-all.sh              # Run all validation tests
├── validate-template.sh         # ARM template validation
├── validate-ui-definition.sh    # UI definition validation
├── test-deployment.sh           # Full deployment integration test
├── cleanup-test-resources.sh    # Clean up test resources
└── parameters/
    └── test-all-new.json        # Test parameters for new resources
```

## Quick Start

### Run All Validations (Recommended)

```bash
cd arm-templates/eventhub-setup
./tests/validate-all.sh
```

This runs both template and UI definition validation without deploying resources.

### Individual Test Commands

**Validate ARM Template:**
```bash
./tests/validate-template.sh
```

**Validate UI Definition:**
```bash
./tests/validate-ui-definition.sh
```

**Full Deployment Test:**
```bash
./tests/test-deployment.sh
```

**Cleanup Test Resources:**
```bash
./tests/cleanup-test-resources.sh
```

## Test Levels

### 1. Static Validation (Fast)
- JSON syntax validation
- Schema compliance
- Required fields check
- Output/parameter mapping

**Runtime:** ~5 seconds
**No Azure resources created**

### 2. Azure Validation (Medium)
- Azure CLI template validation
- What-If deployment preview
- Parameter validation

**Runtime:** ~30 seconds
**Creates test resource group only**

### 3. Integration Test (Slow)
- Full deployment to Azure
- Resource creation verification
- Output validation

**Runtime:** ~5-10 minutes
**Creates actual Azure resources (costs apply)**

## Prerequisites

### Required Tools
- Azure CLI (`az`) - [Install](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- `jq` - JSON processor (`brew install jq` or `apt-get install jq`)
- Bash shell

### Azure Requirements
- Active Azure subscription
- Logged in via `az login`
- Contributor permissions on subscription

### Verify Prerequisites

```bash
# Check Azure CLI
az --version

# Check jq
jq --version

# Check Azure login
az account show

# Check permissions
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

## Test Scenarios

### Scenario 1: All New Resources (Default)
Creates new Event Hub namespace and storage account.

```bash
./tests/validate-template.sh tests/parameters/test-all-new.json
```

### Scenario 2: Existing Namespace
Uses existing Event Hub namespace, creates new storage.

```bash
# Create your parameter file first
./tests/validate-template.sh tests/parameters/test-existing-namespace.json
```

### Scenario 3: Existing Storage
Creates new Event Hub namespace, uses existing storage.

```bash
./tests/validate-template.sh tests/parameters/test-existing-storage.json
```

## UI Definition Testing

### Automated Validation
```bash
./tests/validate-ui-definition.sh
```

This checks:
- JSON syntax
- Required fields
- Schema version
- Output/parameter mapping

### Manual Browser Testing

1. Run the validation script to get the sandbox URL
2. Open: https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/SandboxBlade
3. Load `createUiDefinition.json`
4. Test interactively:
   - Dropdown population
   - Resource selectors
   - Default values
   - Validation messages
   - Output generation

## Continuous Integration

### GitHub Actions

The repository includes automated validation on every push/PR:

- **Trigger:** Push to `main` or PR affecting `arm-templates/**`
- **Tests:** JSON syntax, schema validation, parameter mapping
- **Runtime:** ~1 minute
- **No deployment** (validation only)

View results in the Actions tab of the GitHub repository.

### Running Locally Before Push

```bash
# Run the same checks as CI
cd arm-templates/eventhub-setup
./tests/validate-all.sh
```

## Troubleshooting

### "Not logged into Azure"
```bash
az login
az account set --subscription "Your Subscription Name"
```

### "Resource group already exists"
Normal behavior - tests reuse the resource group. To start fresh:
```bash
./tests/cleanup-test-resources.sh
```

### "Template validation failed"
Check the error message for:
- Invalid parameter values
- Missing required parameters
- Resource naming conflicts
- Permission issues

### "UI definition outputs don't match"
This is a warning, not an error. Review if all template parameters have corresponding UI outputs.

## Best Practices

### Before Every Commit
```bash
./tests/validate-all.sh
```

### Before Major Changes
```bash
./tests/test-deployment.sh  # Full integration test
./tests/cleanup-test-resources.sh  # Clean up after
```

### After Changing Parameters
1. Update test parameter files in `tests/parameters/`
2. Run validation with new parameters
3. Update README if needed

### Keep Test Resources Clean
The test resource group persists for quick iterations. Clean up when done:
```bash
./tests/cleanup-test-resources.sh
```

## Cost Management

**Static validation:** Free
**Azure validation:** Free (only creates resource group)
**Integration test:** Small cost (~$0.01-0.10 for short-lived resources)

**Tip:** Always run `cleanup-test-resources.sh` after integration tests to avoid ongoing charges.

## Contributing

When adding new features:

1. Update test parameter files if new parameters added
2. Run full validation suite
3. Update this README if test procedures change
4. Ensure CI/CD pipeline passes

## Support

For issues with tests:
- Check Prerequisites section
- Review Troubleshooting section
- Open an issue in the repository
