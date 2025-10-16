# Azure Event Hub ARM Template for Edge Delta

This ARM template automates the setup of Azure Event Hub infrastructure for Edge Delta integration.

## What Gets Deployed

This template creates:

- **Event Hub Namespace** - Container for your Event Hub
- **Event Hub** - Named `edgedelta-logs` by default
- **Consumer Group** - Dedicated `edgedelta-processors` group
- **Shared Access Policies**:
  - `AzureSendPolicy` - For Azure services to send logs (Send permission)
  - `EdgeDeltaListenPolicy` - For Edge Delta to consume logs (Listen permission)
- **Storage Account** - For Edge Delta checkpointing
- **Blob Container** - Named `edgedelta-checkpoints`

## Prerequisites

- Azure subscription
- Resource group (create during deployment or use existing)
- Globally unique names for:
  - Event Hub namespace (e.g., `edgedelta-eh-prod-eastus`)
  - Storage account (e.g., `edgedeltachkpt123`)

## Deploy to Azure

Click the button below to deploy:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fedgedelta%2Fdocumentation%2Fprod%2Farm-templates%2Fazure-eventhub-setup.json)

## Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `eventHubNamespaceName` | Name of Event Hub namespace | - | Yes |
| `eventHubName` | Name of Event Hub | `edgedelta-logs` | No |
| `location` | Azure region | Resource group location | No |
| `eventHubSku` | SKU tier | `Standard` | No |
| `partitionCount` | Number of partitions | `4` | No |
| `messageRetentionInDays` | Message retention | `1` | No |
| `storageAccountName` | Storage account name | - | Yes |

## Outputs

After deployment, the template provides these outputs:

- `listenConnectionString` - Use this for Edge Delta configuration
- `sendConnectionString` - Use this for Azure diagnostic settings
- `eventHubName` - Event Hub name
- `consumerGroup` - Consumer group name
- `storageAccountName` - Storage account name
- `storageAccountKey` - Storage account key
- `checkpointContainer` - Checkpoint container name

## Post-Deployment Steps

1. **Copy the outputs** - Save the `listenConnectionString` and storage details
2. **Configure Azure services** - Set up diagnostic settings to stream to this Event Hub
3. **Configure Edge Delta** - Use the connection string in your Event Hub source configuration

See the [Azure Event Hub Setup Guide](../content/en/docs/04-sources/01-log-sources/eventhub-input/azure-setup.md) for detailed instructions.

## Manual Deployment

### Azure CLI

```bash
az deployment group create \
  --resource-group your-resource-group \
  --template-file azure-eventhub-setup.json \
  --parameters eventHubNamespaceName=edgedelta-eh-prod \
               storageAccountName=edgedeltachkpt123
```

### PowerShell

```powershell
New-AzResourceGroupDeployment `
  -ResourceGroupName "your-resource-group" `
  -TemplateFile "azure-eventhub-setup.json" `
  -eventHubNamespaceName "edgedelta-eh-prod" `
  -storageAccountName "edgedeltachkpt123"
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
```

## Support

For issues with the ARM template, please open an issue in the [Edge Delta documentation repository](https://github.com/edgedelta/documentation/issues).
