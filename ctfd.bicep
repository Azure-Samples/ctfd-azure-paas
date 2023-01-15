param nameUniquenss string = uniqueString(resourceGroup().id)

@description('Deploy with VNet')
param vnet bool = true

@description('Server Name for Azure cache for Redis')
param redisServerName string = 'ctfd-redis-${nameUniquenss}'

@description('SKU Name for Azure cache for Redis')
@allowed([
  'Basic'
  'Premium'
  'Standard'
])
param redisSkuName string = 'Standard'

@allowed([
  0
  1
  2
  3
  4
  5
  6
])
@description('The size of the Redis cache')
param redisSkuSize int = 0

@description('Server Name for Azure database for MariaDB')
param mariaServerName string = 'ctfd-mariadb-${nameUniquenss}'

@description('Database administrator login name')
@minLength(1)
param administratorLogin string = 'ctfd'

@description('Database administrator password')
@minLength(8)
@secure()
param administratorLoginPassword string

@description('Database vCores count')
@allowed([
  2
  4
  8
  16
  32
])
param databaseVCores int = 2

@description('Name of Azure Key Vault')
param keyVaultName string = 'ctfd-kv-${nameUniquenss}'

@description('Server Name for Azure app service')
param appServicePlanName string = 'ctfd-server-${nameUniquenss}'

@description('App Service Plan SKU name')
@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
param appServicePlanSkuName string = 'B1'

@description('Name for Azure Web app')
param webAppName string = 'ctfd-app-${nameUniquenss}'

@description('Name for Log Analytics Workspace')
param logAnalyticsName string = 'ctfd-log-analytics-${nameUniquenss}'

@description('Name of the VNet')
param virtualNetworkName string = 'ctf-vnet'

@description('Location for all resources.')
param resourcesLocation string = resourceGroup().location

var resourcesSubnetName = 'resources_subnet'
var integrationSubnetName = 'integration_subnet'
var ctfCacheSecretName = 'ctfd-cache-url'
var ctfDatabaseSecretName = 'ctfd-db-url'

// Scope
targetScope = 'resourceGroup'

module vnetModule 'modules/vnet.bicep' = if (vnet) {
  name: 'vnetDeploy'
  params: {
    location: resourcesLocation
    integrationSubnetName: integrationSubnetName
    resouorcesSubnetName: resourcesSubnetName
    virtualNetworkName: virtualNetworkName
  }
}

module logAnalyticsModule 'modules/loganalytics.bicep' = {
  name: 'logAnalyticsDeploy'
  params: {
    appName: webAppName
    logAnalyticsName: logAnalyticsName
    location: resourcesLocation
  }
}

module ctfWebAppModule 'modules/webapp.bicep' = {
  name: 'ctfDeploy'
  dependsOn: [ vnetModule ]
  params: {
    virtualNetworkName: virtualNetworkName
    location: resourcesLocation
    appServicePlanName: appServicePlanName
    appServicePlanSkuName: appServicePlanSkuName
    keyVaultName: keyVaultName
    ctfCacheUrlSecretName: ctfCacheSecretName
    ctfDatabaseUrlSecretName: ctfDatabaseSecretName
    integrationSubnetName: integrationSubnetName
    webAppName: webAppName
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    vnet: vnet
  }
}

module akvModule 'modules/keyvault.bicep' = {
  name: 'keyVaultDeploy'
  dependsOn: [ ctfWebAppModule ]
  params: {
    keyVaultName: keyVaultName
    location: resourcesLocation
    readerPrincipalId: ctfWebAppModule.outputs.servicePrincipalId
    resourcesSubnetName: resourcesSubnetName
    virtualNetworkName: virtualNetworkName
    vnet: vnet
  }
}

module redisModule 'modules/redis.bicep' = {
  name: 'redisDeploy'
  dependsOn: [ 
    vnetModule
    akvModule
  ]
  params: {
    redisServerName: redisServerName
    virtualNetworkName: virtualNetworkName
    resourcesSubnetName: resourcesSubnetName
    location: resourcesLocation
    vnet: vnet
    ctfCacheSecretName: ctfCacheSecretName
    keyVaultName: keyVaultName
    redisSkuName: redisSkuName
    redisSkuSize: redisSkuSize
  }
}

module mariaDbModule 'modules/mariadb.bicep' = {
  name: 'mariaDbDeploy'
  dependsOn: [ 
    vnetModule
    akvModule
  ]
  params: {
    mariaServerName: mariaServerName
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    virtualNetworkName: virtualNetworkName
    resourcesSubnetName: resourcesSubnetName
    location: resourcesLocation
    vnet: vnet
    ctfDbSecretName: ctfDatabaseSecretName
    keyVaultName: keyVaultName
    databaseVCores: databaseVCores
  }
}
