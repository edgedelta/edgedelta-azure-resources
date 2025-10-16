# Edge Delta Azure Resources

Azure ARM templates and automation scripts for integrating Edge Delta with Azure services.

## Quick Start

Deploy Event Hub infrastructure for Edge Delta:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fedgedelta%2Fedgedelta-azure-resources%2Fmain%2Farm-templates%2Feventhub-setup%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fedgedelta%2Fedgedelta-azure-resources%2Fmain%2Farm-templates%2Feventhub-setup%2FcreateUiDefinition.json)

## What's Included

- **ARM Templates** - One-click deployment of Event Hub infrastructure with automatic subscription activity log configuration
- **Automation Scripts** - PowerShell scripts to auto-configure diagnostic settings for existing Azure resources
- **Examples** - Sample configurations for common Azure services (App Services, VMs, SQL Databases)

## Contents

```
arm-templates/eventhub-setup/    # Event Hub infrastructure deployment
scripts/                         # PowerShell automation for diagnostics
examples/                        # Usage examples for Azure services
docs/                           # Architecture and troubleshooting guides
```

## Usage

1. **Deploy Infrastructure**: Click "Deploy to Azure" button above or use [manual deployment](arm-templates/eventhub-setup/README.md)
2. **Configure Diagnostics**: Run automation scripts to enable log streaming from existing resources
3. **Configure Edge Delta**: Use connection strings from deployment outputs in your Edge Delta configuration

See the [Event Hub setup guide](arm-templates/eventhub-setup/README.md) for detailed instructions.

## Requirements

- Azure subscription with Contributor permissions
- PowerShell 7+ or Azure CLI (for automation scripts)
- Edge Delta account

## Development

### Setup Git Hooks

For contributors, install the pre-commit hook to automatically validate templates:

```bash
./install-hooks.sh
```

This configures Git to run validation tests automatically before each commit, ensuring all templates pass validation before being committed.

### Running Tests

```bash
cd arm-templates/eventhub-setup
./tests/validate-all.sh
```

See [test documentation](arm-templates/eventhub-setup/tests/README.md) for more details.

## Support

- [Edge Delta Documentation](https://docs.edgedelta.com/)
- [GitHub Issues](https://github.com/edgedelta/edgedelta-azure-resources/issues)

## License

Apache License 2.0 - see [LICENSE](LICENSE) for details.
