@description('Deploy in VNet')
param vnet bool

@description('SKU Name for the Azure Storage Account')
param storageSkuName string

@description('Location for all resources.')
param location string

@description('Outbound IP adresses of CTF Web App. Required for the non-vnet scenario')
param webAppOutboundIpAdresses string

@description('Account Name for the Azure Storage Account')
param storageAccountName string

// map the comma-separated string into a json
var networkAcls = vnet ? { defaultAction: 'Deny', bypass: 'AzureServices' } : { defaultAction: 'Allow', ipRules: map(split(webAppOutboundIpAdresses, ','), ip => { value: ip }) }

resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource updateNetworkAcls  'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: existingStorageAccount.name
  location: location
  sku: {
    name: storageSkuName
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: networkAcls
  }
}
