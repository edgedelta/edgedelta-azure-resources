# PR Summary: Subscription-Level Template Migration (v1.0.12)

> **Related Documentation**: This PR implements [specs/plan-2025-10-17.md](./plan-2025-10-17.md)

## Summary

This PR migrates the Edge Delta Event Hub ARM template from resource group-level to subscription-level deployment, enabling automatic configuration of Azure activity logs. This addresses the deployment failure for subscription diagnostic settings that occurred in v1.0.11.

## Problem Statement

**v1.0.11 Issue**: Template attempted to deploy subscription-level diagnostic settings from a resource group-level deployment, which is not supported by Azure ARM. This caused deployments to fail with:
```
ResourceTypeNotSupported: The resource type '/' does not support diagnostic settings
```

**Root Cause**: Azure's scope hierarchy prohibits upward transitions. Resource Group → Subscription deployments are not allowed.

## Solution

Migrated to subscription-level template (`subscriptionDeploymentTemplate.json#` schema) with nested deployment pattern:
- Main template deploys at subscription scope
- Nested deployment targets existing resource group for Event Hub/storage resources
- Diagnostic settings deploy directly at subscription level (when enabled)

See [Implementation Plan](./plan-2025-10-17.md) for detailed architecture and checklist.

## Breaking Changes

⚠️ **IMPORTANT**: Users must now provide an **existing resource group**. The template no longer creates resource groups.

### Migration Path

**Before (v1.0.11)**:
```bash
az deployment group create \
  --resource-group my-resource-group \
  --template-file azuredeploy.json
```

**After (v1.0.12)**:
```bash
# 1. Create resource group first
az group create --name my-resource-group --location eastus

# 2. Deploy at subscription level
az deployment sub create \
  --location eastus \
  --template-file azuredeploy.json \
  --parameters resourceGroupName=my-resource-group
```

## Implementation Summary

All phases from [plan-2025-10-17.md](./plan-2025-10-17.md) completed successfully:

### ✅ Phase 0: Preparation & Setup
- Created comprehensive 927-line implementation plan
- Created feature branch `daniel-edgedelta/subscription-level-template`
- Created backup tag `v1.0.11-final`
- Documented current outputs for compatibility

### ✅ Phase 1: Template Restructuring (31 tasks)
- Changed schema to `subscriptionDeploymentTemplate.json#`
- Updated version to 1.0.12.0
- Added `resourceGroupName` parameter (required)
- Removed `createNewResourceGroup` logic per user requirement
- Created nested deployment for resource group resources
- Moved diagnostic settings to subscription level

### ✅ Phase 2: UI Definition Updates (12 tasks)
- Updated version to 1.0.12
- Added "Resource Group" wizard step with ResourceSelector
- Added prerequisite InfoBox about existing RG requirement
- Updated outputs to include resourceGroupName

### ✅ Phase 3: Safety Mechanisms (21 tasks)
- Created `test-deployment-whatif.sh` for safe previews
- Created `cleanup.sh` (Bash) for local dev cleanup
- Created `cleanup.ps1` (PowerShell) per user requirement
- All scripts include prominent warnings and confirmations
- Updated tests/README.md with comprehensive documentation

### ✅ Phase 4: Documentation Updates (23 tasks)
- Updated main README for subscription-level deployment
- Changed all examples to `az deployment sub create`
- Updated "Deploy to Azure" button URLs to v1.0.12
- Added what-if testing documentation
- Documented cleanup scripts with dev-only warnings

### ✅ Phase 5: Comprehensive Testing (27 tasks)
All manual deployment tests passed:
- ✅ Deploy all new resources (8 resources in 40s)
- ✅ Verify all outputs (connection strings, keys, metadata)
- ✅ Test cleanup scripts (interactive prompts working)
- ✅ Deploy with activity logs (diagnostic settings created)
- ✅ Resource cleanup (successful deletion)

## Technical Issues Resolved

### Issue 1: Azure CLI Validation Bug
**Problem**: Azure CLI 2.74.0 had "content already consumed" error
**Solution**: Updated to 2.78.0, revealed actual template errors

### Issue 2: resourceId() Scope in Subscription Templates
**Problem**: `resourceId(resourceGroupName, type, name)` failed with "not valid subscription identifier"
**Solution**: Added subscription ID as first parameter:
```json
resourceId(subscription().subscriptionId, parameters('resourceGroupName'), 'type', 'name')
```

### Issue 3: listKeys() Cross-Scope Failures
**Problem**: `listKeys()` in subscription outputs tried to access RG-scoped resources at subscription scope
**Solution**: Moved `listKeys()` calls into nested deployment outputs:
```json
// Inner template (resource group scope) - can call listKeys()
"outputs": {
  "connectionString": {
    "value": "[listKeys(resourceId('Microsoft.EventHub/...'), '2022-10-01').primaryConnectionString]"
  }
}

// Outer template (subscription scope) - references nested outputs
"outputs": {
  "connectionString": {
    "value": "[reference('nestedDeployment').outputs.connectionString.value]"
  }
}
```

## Testing Results

### Test 1: Deploy All New Resources ✅
- **Result**: 8 resources created successfully
- **Duration**: 40 seconds
- **State**: provisioningState = Succeeded
- **Outputs**: All populated correctly

### Test 2: Verify Outputs ✅
- connectionString (Listen permission): ✅
- azureDiagnosticConnectionString (Send permission): ✅
- storageAccountKey: ✅
- All metadata fields: ✅

### Test 3: Cleanup Scripts ✅
- cleanup.sh interactive prompts: ✅
- Resource deletion: ✅
- Warning banners displayed: ✅

### Test 4: Activity Logs Configuration ✅
- Diagnostic settings created at subscription level: ✅
- All 8 log categories enabled: ✅
- Event Hub correctly configured: ✅
- Unique name generated (with uniqueString): ✅

### Test 5: Resource Cleanup ✅
- Diagnostic settings deletion: ✅
- Resource group cleanup: ✅

## Files Changed

### Core Template Files
- `arm-templates/eventhub-setup/azuredeploy.json` - Restructured to subscription-level
- `arm-templates/eventhub-setup/createUiDefinition.json` - Added RG selector

### Documentation
- `arm-templates/eventhub-setup/README.md` - Updated for v1.0.12
- `arm-templates/eventhub-setup/tests/README.md` - Added safety mechanisms section
- `README.md` - Updated Deploy to Azure button

### Testing & Safety
- `arm-templates/eventhub-setup/tests/test-deployment-whatif.sh` - NEW
- `arm-templates/eventhub-setup/tests/cleanup.sh` - NEW
- `arm-templates/eventhub-setup/tests/cleanup.ps1` - NEW
- `arm-templates/eventhub-setup/tests/validate-template.sh` - Updated for subscription validation

### Planning & Reference
- `specs/plan-2025-10-17.md` - NEW (927 lines, 127 checkboxes)
- `specs/pr-summary-v1.0.12.md` - NEW (this document)
- `.claude/skills/arm-template-functions/SKILL.md` - NEW (reusable reference)

## Deployment Instructions

### Prerequisites
1. Azure CLI installed and logged in (`az login`)
2. Contributor or Owner permissions on subscription
3. **Existing resource group** (create before deployment)

### Quick Start
```bash
# 1. Create resource group
az group create --name my-rg --location eastus

# 2. Preview changes (recommended)
az deployment sub what-if \
  --location eastus \
  --template-file azuredeploy.json \
  --parameters \
    resourceGroupName=my-rg \
    eventHubNamespaceName=my-namespace-123 \
    storageAccountName=mystg123 \
    location=eastus

# 3. Deploy
az deployment sub create \
  --name my-deployment \
  --location eastus \
  --template-file azuredeploy.json \
  --parameters \
    resourceGroupName=my-rg \
    eventHubNamespaceName=my-namespace-123 \
    storageAccountName=mystg123 \
    location=eastus \
    configureActivityLogs=true
```

### Using What-If Script
```bash
cd arm-templates/eventhub-setup
./tests/test-deployment-whatif.sh
# Follow interactive prompts
```

## Rollback Plan

If issues are discovered post-merge:

1. **Revert to v1.0.11**:
   ```bash
   git revert <merge-commit> --no-commit
   git commit -m "Rollback to v1.0.11"
   ```

2. **Users can continue using v1.0.11** via URL:
   ```
   https://portal.azure.com/#create/Microsoft.Template/uri/.../azuredeploy.json?v=1.0.11
   ```

3. **No data loss**: All deployments are additive; resources remain intact

4. **Cleanup test resources**:
   ```bash
   cd arm-templates/eventhub-setup
   ./tests/cleanup.sh  # or cleanup.ps1
   ```

## Post-Merge Checklist

- [ ] Monitor initial production deployments
- [ ] Update Edge Delta documentation site
- [ ] Create GitHub release for v1.0.12
- [ ] Tag release: `git tag v1.0.12 && git push --tags`
- [ ] Update Deploy to Azure button cache parameter
- [ ] Notify users of breaking change via changelog

## Commits

10 commits implementing v1.0.12:

1. `a79f60c` - Add comprehensive implementation plan
2. `1670c97` - Update plan: require existing RG, add PowerShell cleanup
3. `4c6319e` - Phase 1: Restructure ARM template to subscription-level
4. `967a556` - Phase 2: Update UI definition with RG selector
5. `6ea88cb` - Phase 3: Create safety mechanisms (what-if, cleanup scripts)
6. `8b09891` - Phase 4: Update all documentation for v1.0.12
7. `c6dad73` - Add ARM Template Functions skill
8. `f4f3d98` - Fix: Add subscription().subscriptionId to resourceId()
9. `ae72f4b` - Update ARM Template Functions skill with pattern
10. `c5f8244` - Fix: Move listKeys() to nested deployment outputs

## Additional Resources

- **Implementation Plan**: [specs/plan-2025-10-17.md](./plan-2025-10-17.md) - Detailed architecture and task breakdown
- **ARM Functions Skill**: [.claude/skills/arm-template-functions/SKILL.md](../.claude/skills/arm-template-functions/SKILL.md) - Reusable reference for future work
- **Testing Guide**: [arm-templates/eventhub-setup/tests/README.md](../arm-templates/eventhub-setup/tests/README.md) - Safety mechanisms documentation

## Questions?

For questions or issues with this PR:
1. Review the [comprehensive plan](./plan-2025-10-17.md) (927 lines, all phases documented)
2. Check [test documentation](../arm-templates/eventhub-setup/tests/README.md) for safety mechanisms
3. Review [ARM functions skill](../.claude/skills/arm-template-functions/SKILL.md) for technical details
4. Run `./tests/test-deployment-whatif.sh` to preview changes safely
