@description('Deploy in VNet')
param vnet bool

@description('Server Name for Azure cache for Redis')
param redisServerName string

@description('SKU Name for Azure cache for Redis')
param redisSkuName string

@description('The size of the Redis cache')
param redisSkuSize int

@description('Name of the VNet')
param virtualNetworkName string

@description('Name of the resources subnet')
param resourcesSubnetName string

@description('Name of the key vault')
param keyVaultName string

@description('Name of the connection string secret')
param ctfCacheSecretName string

@description('Location for all resources.')
param location string

var family = redisSkuName ==  'Basic' || redisSkuName ==  'Standard' ? 'C' : 'P'

resource redis_cache 'Microsoft.Cache/redis@2022-06-01' = {
  name: redisServerName
  location: location
  properties: {
    enableNonSslPort: true
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
    subnetName: resourcesSubnetName
    resuorceId: redis_cache.id
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
    secretValue: 'redis://:${redis_cache.listKeys().primaryKey}@${redisServerName}.redis.cache.windows.net'
  }
}
