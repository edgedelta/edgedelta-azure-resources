# Cleanup Script for Edge Delta Event Hub ARM Template Deployments
#
# ⚠️  WARNING: FOR LOCAL DEVELOPMENT AND TESTING ONLY
#
# This script helps clean up failed or test deployments by removing:
# - Subscription-level diagnostic settings
# - Event Hub resources
# - Storage accounts
# - Deployments
#
# USE WITH CAUTION: This script deletes resources and cannot be undone.
# Always review what will be deleted before confirming.

# Check prerequisites
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "✗ Azure CLI not installed" -ForegroundColor Red
    exit 1
}

try {
    $null = az account show 2>&1
} catch {
    Write-Host "✗ Not logged into Azure" -ForegroundColor Red
    Write-Host "  Run 'az login' to authenticate"
    exit 1
}

# Banner
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║                                                            ║" -ForegroundColor Red
Write-Host "║         ⚠️  CLEANUP SCRIPT - USE WITH CAUTION ⚠️           ║" -ForegroundColor Red
Write-Host "║                                                            ║" -ForegroundColor Red
Write-Host "║    FOR LOCAL DEVELOPMENT AND TESTING ONLY                  ║" -ForegroundColor Red
Write-Host "║                                                            ║" -ForegroundColor Red
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""
Write-Host "This script will DELETE Azure resources. This action CANNOT be undone." -ForegroundColor Yellow
Write-Host ""

# Get subscription info
$subscriptionId = az account show --query id -o tsv
$subscriptionName = az account show --query name -o tsv

Write-Host "✓ Connected to Azure" -ForegroundColor Green
Write-Host "  Subscription: $subscriptionName"
Write-Host "  ID: $subscriptionId"
Write-Host ""

# Menu
Write-Host "What would you like to clean up?"
Write-Host ""
Write-Host "  1) List all diagnostic settings (subscription-level)"
Write-Host "  2) Delete diagnostic settings by pattern"
Write-Host "  3) Clean up test deployment resources"
Write-Host "  4) List all deployments"
Write-Host "  5) Exit"
Write-Host ""

$option = Read-Host "Choose an option (1-5)"

switch ($option) {
    "1" {
        Write-Host ""
        Write-Host "=========================================="
        Write-Host "Subscription Diagnostic Settings"
        Write-Host "=========================================="
        Write-Host ""
        az monitor diagnostic-settings subscription list --output table
    }
    "2" {
        Write-Host ""
        $pattern = Read-Host "Enter pattern to match (e.g., 'edgedelta-activity-logs')"
        Write-Host ""
        Write-Host "Searching for diagnostic settings matching: $pattern"
        Write-Host ""

        $settingsJson = az monitor diagnostic-settings subscription list --query "[?contains(name, '$pattern')].name" -o json | ConvertFrom-Json

        if ($settingsJson.Count -eq 0) {
            Write-Host "No diagnostic settings found matching '$pattern'"
            exit 0
        }

        Write-Host "Found diagnostic settings:"
        $settingsJson | ForEach-Object { Write-Host "  $_" }
        Write-Host ""
        Write-Host "WARNING: This will DELETE the above diagnostic settings." -ForegroundColor Red
        $confirm = Read-Host "Are you sure? Type 'yes' to confirm"

        if ($confirm -eq "yes") {
            foreach ($setting in $settingsJson) {
                Write-Host "Deleting: $setting"
                az monitor diagnostic-settings subscription delete --name $setting --yes
                Write-Host "✓ Deleted: $setting" -ForegroundColor Green
            }
            Write-Host ""
            Write-Host "Cleanup complete!" -ForegroundColor Green
        } else {
            Write-Host "Cancelled."
        }
    }
    "3" {
        Write-Host ""
        $resourceGroup = Read-Host "Resource group name"

        try {
            $null = az group show --name $resourceGroup 2>&1
        } catch {
            Write-Host "✗ Resource group not found: $resourceGroup" -ForegroundColor Red
            exit 1
        }

        Write-Host ""
        Write-Host "Resources in $resourceGroup:"
        Write-Host ""
        az resource list --resource-group $resourceGroup --query "[].{Name:name, Type:type}" -o table
        Write-Host ""
        Write-Host "WARNING: This will DELETE the entire resource group and ALL resources in it." -ForegroundColor Red
        $confirm = Read-Host "Are you sure you want to delete resource group '$resourceGroup'? Type 'DELETE' to confirm"

        if ($confirm -eq "DELETE") {
            Write-Host "Deleting resource group: $resourceGroup"
            az group delete --name $resourceGroup --yes --no-wait
            Write-Host "✓ Deletion initiated (running in background)" -ForegroundColor Green
            Write-Host "  Check status: az group show --name '$resourceGroup'"
        } else {
            Write-Host "Cancelled."
        }
    }
    "4" {
        Write-Host ""
        Write-Host "=========================================="
        Write-Host "Recent Subscription Deployments"
        Write-Host "=========================================="
        Write-Host ""
        az deployment sub list --query "[?properties.timestamp>'2025-01-01'].{Name:name, Status:properties.provisioningState, Timestamp:properties.timestamp}" -o table
        Write-Host ""
        $deletePrompt = Read-Host "Delete a deployment? (y/n)"
        if ($deletePrompt -eq "y") {
            $deployName = Read-Host "Deployment name"
            Write-Host "Deleting deployment: $deployName"
            az deployment sub delete --name $deployName
            Write-Host "✓ Deleted deployment" -ForegroundColor Green
        }
    }
    "5" {
        Write-Host "Exiting."
        exit 0
    }
    default {
        Write-Host "Invalid option."
        exit 1
    }
}

Write-Host ""
