@description('Deploy in VNet')
param vnet bool

@description('Name of the key vault.')
param keyVaultName string

@description('Location for all resources.')
param location string

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param readerPrincipalId string

@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
param keysPermissions array = [
  'list'
  'get'
]

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
param secretsPermissions array = [
  'list'
  'get'
]

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Name of the VNet')
param virtualNetworkName string

@description('Name of the resources subnet')
param resourcesSubnetName string

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    publicNetworkAccess: (vnet ? 'Disabled' : 'Enabled')
    accessPolicies: [
      {
        objectId: readerPrincipalId
        tenantId: tenantId
        permissions: {
          keys: keysPermissions
          secrets: secretsPermissions
        }
      }
    ]
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

module privateEndpointModule 'privateendpoint.bicep' = if (vnet) {
  name: 'keyVaultPrivateEndpointDeploy'
  params: {
    virtualNetworkName: virtualNetworkName
    subnetName: resourcesSubnetName
    resuorceId: kv.id
    resuorceGroupId: 'vault'
    privateDnsZoneName: 'privatelink.vaultcore.azure.net'
    privateEndpointName: 'keyvault_private_endpoint'
    location: location
  }
}
