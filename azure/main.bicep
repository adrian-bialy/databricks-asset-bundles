@description('Prefix for all resources, 3–11 lowercase letters/numbers')
@minLength(3)
@maxLength(11)
param prefix string

@description('Region to deploy resources')
param location string = resourceGroup().location

@description('Object ID of the user who should be granted the Key Vault Secrets Officer role.')
@maxLength(36)
param currentUserObjectId string

// Key Vault
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${prefix}-kv'
  location: location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
    enableRbacAuthorization: true
    enabledForDeployment: true
  }
}

// Assign the current user the Key Vault Secrets Officer role
// The built‑in role ID for Key Vault Secrets Officer is b86a8fe4‑44ce‑4948‑aee5‑eccb2c155cd7【955605250858674†L92-L94】.
resource secretsOfficerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, currentUserObjectId, 'secretsOfficer')
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
    principalId: currentUserObjectId
    principalType: 'User'
  }
}

// Databricks Workspace (trial SKU) – uses a managed resource group per workspace.
resource dbx 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: '${prefix}-dbx'
  location: location
  sku: {
    name: 'trial'
  }
  properties: {
    managedResourceGroupId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${prefix}-dbx-managed'
  }
}

// Outputs
output keyVaultName string = kv.name
output databricksWorkspaceName string = dbx.name
