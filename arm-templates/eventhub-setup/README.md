# Azure Event Hub ARM Template for Edge Delta

This ARM template automates the setup of Azure Event Hub infrastructure for Edge Delta integration at the subscription level. This enables automatic configuration of subscription activity logs while creating Event Hub and storage resources in an existing resource group. It supports both creating new resources and using existing Event Hub namespaces and storage accounts.

## Deployment Modes

**Create All New Resources (Default)**
- Creates Event Hub namespace, Event Hub, storage account, and all required configurations

**Use Existing Namespace**
- Creates Event Hub within your existing namespace
- Useful if you already have Event Hub namespace infrastructure

**Use Existing Storage Account**
- Creates checkpoint container in your existing storage account
- Useful for standardized storage configurations

**Use Both Existing**
- Maximum flexibility - uses existing infrastructure for both Event Hub and storage

## What Gets Deployed

This template always creates:
- **Event Hub** - Named `edgedelta-logs` by default (created in new or existing namespace)
- **Consumer Group** - Dedicated `edgedelta-processors` group
- **Shared Access Policies**:
  - `AzureSendPolicy` - For Azure services to send logs (Send permission)
  - `EdgeDeltaListenPolicy` - For Edge Delta to consume logs (Listen permission)
- **Blob Container** - Named `edgedelta-checkpoints` (in new or existing storage account)

Optionally creates (based on parameters):
- **Event Hub Namespace** - If creating new
- **Storage Account** - If creating new
- **Subscription Activity Log Diagnostic Settings** - Can automatically configure activity logs (manual configuration recommended)

## What's Included

This deployment includes:
- **azuredeploy.json** - ARM template for infrastructure
- **createUiDefinition.json** - Interactive deployment UI with resource pickers

The UI definition provides an enhanced deployment experience with:
- Location picker dropdown
- Resource selectors for existing Event Hub namespaces
- Resource selectors for existing storage accounts
- Input validation and helpful tooltips

## Prerequisites

- Azure subscription with Contributor or Owner permissions
- **Existing resource group** (must be created before deployment)
- Globally unique names for new resources:
  - Event Hub namespace (e.g., `edgedelta-eh-prod-eastus`)
  - Storage account (e.g., `edgedeltachkpt123`)

**Important Notes:**
- **v1.0.12+**: This template deploys at subscription level and requires an existing resource group. Create the resource group first: `az group create --name your-resource-group --location eastus`
- Edge Delta requires **Standard or Premium tier** Event Hub namespace. The Basic tier does not support consumer groups, which are required for Edge Delta's Event Processor Host model. If selecting an existing namespace, ensure it is Standard or Premium tier.

## Deploy to Azure

Click the button below to deploy with an interactive UI that shows dropdowns for existing resources:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fedgedelta%2Fedgedelta-azure-resources%2Fmain%2Farm-templates%2Feventhub-setup%2Fazuredeploy.json%3Ft%3D20251017152000/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fedgedelta%2Fedgedelta-azure-resources%2Fmain%2Farm-templates%2Feventhub-setup%2FcreateUiDefinition.json%3Ft%3D20251017152000)

> **v1.0.12+**: The deployment wizard will first prompt you to select an existing resource group, then show resource pickers for existing Event Hub namespaces and storage accounts when you select "Use existing".

## Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `resourceGroupName` | Name of existing resource group for Event Hub and storage | - | Yes |
| `location` | Azure region (dropdown picker) | - | Yes |
| `useExistingNamespace` | Use existing Event Hub namespace | `false` | No |
| `eventHubNamespaceName` | Name of Event Hub namespace (existing or new) | - | Yes |
| `eventHubSku` | SKU tier (only for new namespace) | `Standard` | No |
| `eventHubName` | Name of Event Hub to create | `edgedelta-logs` | No |
| `partitionCount` | Number of partitions | `4` | No |
| `messageRetentionInDays` | Message retention | `1` | No |
| `configureActivityLogs` | Auto-configure subscription activity logs | `false` | No |
| `useExistingStorageAccount` | Use existing storage account | `false` | No |
| `storageAccountName` | Storage account name (existing or new) | - | Yes |

## Outputs

After deployment, the template provides these outputs mapped directly to Edge Delta UI fields:

**For Edge Delta Azure Event Hub Source Configuration:**

| Output Name | Edge Delta UI Field | Value |
|-------------|---------------------|-------|
| `connectionString` | Connection String (required) | Event Hub connection string with Listen permission |
| `consumerGroup` | Consumer Group (optional) | `edgedelta-processors` |
| `storageAccountName` | Storage Account Name (optional) | Storage account name |
| `storageAccountKey` | Storage Account Key (optional) | Storage account access key |
| `storageContainerName` | Storage Container Name (optional) | `edgedelta-checkpoints` |

**For Azure Diagnostic Settings:**
- `azureDiagnosticConnectionString` - Event Hub connection string with Send permission (use when configuring Azure resources to stream logs)

**Deployment Information:**
- `eventHubNamespace` - Event Hub namespace name
- `eventHubName` - Event Hub name
- `deploymentSummary` - Shows which resources were created vs. existing
- `activityLogsConfigured` - Confirms whether subscription activity logs were automatically configured
- `instructions` - Quick guidance on using the outputs

> **Security Note:** Connection strings and storage keys are sensitive. The deployment outputs are stored in Azure deployment history. Ensure only authorized personnel have access to the resource group.

## Post-Deployment Steps

1. **Configure Edge Delta** - In your Edge Delta portal, create an Azure Event Hub Source and copy each output value to its corresponding field:
   - `connectionString` → Connection String field
   - `consumerGroup` → Consumer Group field
   - `storageAccountName` → Storage Account Name field
   - `storageAccountKey` → Storage Account Key field
   - `storageContainerName` → Storage Container Name field

2. **Configure Subscription Activity Logs** (Recommended) - Manually configure Azure subscription activity logs:
   - Navigate to Azure Portal → Monitor → Diagnostic settings
   - Click "Add diagnostic setting"
   - Select all log categories you want (Administrative, Security, Service Health, etc.)
   - Choose "Stream to an event hub"
   - Select your Event Hub namespace and `edgedelta-logs` Event Hub
   - Use the `azureDiagnosticConnectionString` authorization (or select RootManageSharedAccessKey)
   - Click "Save"

3. **Configure Additional Resource Diagnostic Settings** (Optional) - Set up individual Azure resources to stream their logs to this Event Hub:
   - Use the `azureDiagnosticConnectionString` output when configuring diagnostic settings
   - See [Azure streaming setup guide](https://docs.edgedelta.com/event-hub-source-node/azure-streaming-setup/) for step-by-step instructions

4. **Verify** - Check that events are flowing:
   - Azure Portal: Monitor Event Hub metrics for incoming messages
   - Edge Delta: Verify logs are being received in your pipeline

## Manual Deployment

> **v1.0.12+ Important**: This template uses subscription-level deployment. Use `az deployment sub create` (not `az deployment group create`).

### Prerequisites

**Create resource group first:**
```bash
az group create --name your-resource-group --location eastus
```

### Test Deployment (What-If)

Preview changes before deploying (recommended):
```bash
az deployment sub what-if \
  --location eastus \
  --template-file azuredeploy.json \
  --parameters \
    resourceGroupName=your-resource-group \
    eventHubNamespaceName=edgedelta-eh-prod-123 \
    storageAccountName=edgedeltachkpt123 \
    location=eastus \
    configureActivityLogs=false
```

### Create All New Resources

**Azure CLI:**
```bash
az deployment sub create \
  --name edgedelta-eventhub-deployment \
  --location eastus \
  --template-file azuredeploy.json \
  --parameters \
    resourceGroupName=your-resource-group \
    eventHubNamespaceName=edgedelta-eh-prod-123 \
    storageAccountName=edgedeltachkpt123 \
    location=eastus \
    configureActivityLogs=false
```

**PowerShell:**
```powershell
New-AzDeployment `
  -Name "edgedelta-eventhub-deployment" `
  -Location "eastus" `
  -TemplateFile "azuredeploy.json" `
  -resourceGroupName "your-resource-group" `
  -eventHubNamespaceName "edgedelta-eh-prod-123" `
  -storageAccountName "edgedeltachkpt123" `
  -location "eastus" `
  -configureActivityLogs $false
```

### Use Existing Namespace

**Azure CLI:**
```bash
az deployment sub create \
  --name edgedelta-eventhub-deployment \
  --location eastus \
  --template-file azuredeploy.json \
  --parameters \
    resourceGroupName=your-resource-group \
    eventHubNamespaceName=my-existing-namespace \
    storageAccountName=edgedeltachkpt123 \
    location=eastus \
    useExistingNamespace=true \
    configureActivityLogs=false
```

**PowerShell:**
```powershell
New-AzDeployment `
  -Name "edgedelta-eventhub-deployment" `
  -Location "eastus" `
  -TemplateFile "azuredeploy.json" `
  -resourceGroupName "your-resource-group" `
  -eventHubNamespaceName "my-existing-namespace" `
  -storageAccountName "edgedeltachkpt123" `
  -location "eastus" `
  -useExistingNamespace $true `
  -configureActivityLogs $false
```

### Use Existing Storage Account

**Azure CLI:**
```bash
az deployment sub create \
  --name edgedelta-eventhub-deployment \
  --location eastus \
  --template-file azuredeploy.json \
  --parameters \
    resourceGroupName=your-resource-group \
    eventHubNamespaceName=edgedelta-eh-prod-123 \
    storageAccountName=my-existing-storage \
    location=eastus \
    useExistingStorageAccount=true \
    configureActivityLogs=false
```

### Use Both Existing Resources

**PowerShell:**
```powershell
New-AzDeployment `
  -Name "edgedelta-eventhub-deployment" `
  -Location "eastus" `
  -TemplateFile "azuredeploy.json" `
  -resourceGroupName "your-resource-group" `
  -eventHubNamespaceName "my-existing-namespace" `
  -storageAccountName "my-existing-storage" `
  -location "eastus" `
  -useExistingNamespace $true `
  -useExistingStorageAccount $true `
  -configureActivityLogs $false
```

## Estimated Costs

Based on Standard tier with default settings:
- Event Hub Standard: ~$10-20/month (base + throughput)
- Storage Account: ~$1-5/month (checkpoint data is minimal)

**Total: ~$11-25/month**

Costs vary by region, throughput, and data volume.

## Security Considerations

- Storage account has public blob access disabled
- TLS 1.2 minimum enforced
- Separate policies for Send (Azure) and Listen (Edge Delta)
- Connection strings available only in deployment outputs

## Troubleshooting

**Error: "Cannot perform operation on entity type 'ConsumerGroup' because namespace is using 'Basic' tier"**
- Edge Delta requires Standard or Premium tier Event Hub namespace
- Basic tier does not support consumer groups
- Solution: Either upgrade existing namespace to Standard/Premium, or select a different namespace, or create a new Standard/Premium namespace

**Namespace name already exists:**
- Event Hub namespaces must be globally unique
- Try adding region or timestamp: `edgedelta-eh-eastus-20241016`

**Storage account name invalid:**
- Must be 3-24 characters, lowercase letters and numbers only
- Must be globally unique

**Deployment fails:**
- Check subscription quotas for Event Hubs and Storage
- Verify you have Contributor or Owner role on resource group

## Clean Up

To delete all resources created by this template:

```bash
# Delete the resource group (deletes everything in it)
az group delete --name your-resource-group --yes

# If activity logs were configured, delete the diagnostic setting
az monitor diagnostic-settings subscription delete --name edgedelta-activity-logs-<uniquestring>
```

### Development Cleanup Tools (v1.0.12+)

For local development and testing, interactive cleanup scripts are available in `tests/`:

```bash
# Bash (Linux/macOS)
./tests/cleanup.sh

# PowerShell (Windows/cross-platform)
./tests/cleanup.ps1
```

**Features:**
- List subscription diagnostic settings
- Delete diagnostic settings by pattern
- Clean up resource groups
- View and delete deployments

⚠️ **WARNING**: These are for local development only. Use with caution as deletions cannot be undone.

See [tests/README.md](tests/README.md#safety-mechanisms-v1012) for detailed documentation.

## Support

For issues with the ARM template, please open an issue in the [Edge Delta Azure Resources repository](https://github.com/edgedelta/edgedelta-azure-resources/issues).
