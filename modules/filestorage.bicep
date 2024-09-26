@description('Deploy in VNet')
param vnet bool

@description('SKU Name for the Azure Storage Account')
param storageSkuName string

@description('Name of the VNet')
param virtualNetworkName string

@description('Name of the internal resources subnet')
param internalResourcesSubnetName string

@description('Location for all resources.')
param location string

@description('Log Anaytics Workspace Id')
param logAnalyticsWorkspaceId string

@description('Account Name for the Azure Storage Account')
param storageAccountName string

module privateEndpointModule 'privateendpoint.bicep' = if (vnet) {
  name: 'storagePrivateEndpointDeploy'
  params: {
    virtualNetworkName: virtualNetworkName
    subnetName: internalResourcesSubnetName
    resuorceId: storageAccount.id
    resuorceGroupId: 'file'
    privateDnsZoneName: 'privatelink.file.${environment().suffixes.storage}'
    privateEndpointName: 'storage_private_endpoint'
    location: location
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSkuName
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: (vnet ? 'Disabled' : 'Enabled')
    accessTier: 'Hot'
  }
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: fileServices
  name: 'uploads'
  properties: {}
}

resource diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccountName}-diagnostics'
  scope: fileServices
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

output storageAccountName string = storageAccountName
