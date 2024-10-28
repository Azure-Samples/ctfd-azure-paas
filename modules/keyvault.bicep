@description('Deploy in VNet')
param vnet bool

@description('Location for all resources.')
param location string

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param readerPrincipalId string

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Name of the VNet')
param virtualNetworkName string

@description('Name of the internal resources subnet')
param internalResourcesSubnetName string

@description('Name of Azure Key Vault')
param keyVaultName string

@description('Log Anaytics Workspace Id')
param logAnalyticsWorkspaceId string

@description('Outbound IP adresses of CTF Web App. Required for the non-vnet scenario')
param webAppOutboundIpAdresses string

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
var tenantId = subscription().tenantId

// map the comma-separated string into a json
var networkAcls = vnet ? { defaultAction: 'Deny', bypass: 'AzureServices' } : { defaultAction: 'Allow', ipRules: map(split(webAppOutboundIpAdresses, ','), ip => { value: ip }) }

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    publicNetworkAccess: (vnet ? 'Disabled' : 'Enabled')
    enableRbacAuthorization: true
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: networkAcls
  }
}

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('4633458b-17de-408a-b874-0445c86b69e6', readerPrincipalId, keyVault.id)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: readerPrincipalId
    principalType: 'ServicePrincipal'
  }
}

module privateEndpointModule 'privateendpoint.bicep' = if (vnet) {
  name: 'keyVaultPrivateEndpointDeploy'
  params: {
    virtualNetworkName: virtualNetworkName
    subnetName: internalResourcesSubnetName
    resuorceId: keyVault.id
    resuorceGroupId: 'vault'
    privateDnsZoneName: 'privatelink.vaultcore.azure.net'
    privateEndpointName: 'keyvault_private_endpoint'
    location: location
  }
}

resource diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${keyVaultName}-diagnostics'
  scope: keyVault
  properties: {
    logs: [
      {
        category: null
        categoryGroup: 'audit'
        enabled: true
        retentionPolicy: {
          days: 5
          enabled: false
        }
      }
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 5
          enabled: false
        }
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}

output keyVaultName string = keyVaultName
