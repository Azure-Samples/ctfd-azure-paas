@description('Deploy in VNet')
param vnet bool

@description('SKU Name for Azure cache for Redis')
param redisSkuName string

@description('The size of the Redis cache')
param redisSkuSize int

@description('Name of the VNet')
param virtualNetworkName string

@description('Name of the internal resources subnet')
param internalResourcesSubnetName string

@description('Name of the key vault')
param keyVaultName string

@description('Name of the connection string secret')
param ctfCacheSecretName string

@description('Location for all resources.')
param location string

@description('Log Anaytics Workspace Id')
param logAnalyticsWorkspaceId string

@description('Server Name for Azure cache for Redis')
var redisServerName = 'ctfd-redis-${uniqueString(resourceGroup().id)}'

var family = redisSkuName == 'Basic' || redisSkuName == 'Standard' ? 'C' : 'P'

resource redisCache 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisServerName
  location: location
  properties: {
    publicNetworkAccess: (vnet ? 'Disabled' : 'Enabled')
    sku: {
      capacity: redisSkuSize
      family: family
      name: redisSkuName
    }
  }
}

module privateEndpointModule 'privateendpoint.bicep' = if (vnet) {
  name: 'redisPrivateEndpointDeploy'
  params: {
    virtualNetworkName: virtualNetworkName
    subnetName: internalResourcesSubnetName
    resuorceId: redisCache.id
    resuorceGroupId: 'redisCache'
    privateDnsZoneName: 'privatelink.redis.cache.windows.net'
    privateEndpointName: 'redis_private_endpoint'
    location: location
  }
}

module cacheSecret 'keyvaultsecret.bicep' = {
  name: 'redisKeyDeploy'
  params: {
    keyVaultName: keyVaultName
    secretName: ctfCacheSecretName
    secretValue: 'rediss://:${redisCache.listKeys().primaryKey}@${redisCache.name}.redis.cache.windows.net:6380'
  }
}

resource diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${redisServerName}-diagnostics'
  scope: redisCache
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
          days:5
          enabled: false
        }
      }
    ]
    workspaceId: logAnalyticsWorkspaceId
  }
}
