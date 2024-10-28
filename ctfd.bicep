@description('Location for all resources.')
param resourcesLocation string = resourceGroup().location

@description('Deploy with VNet')
param vnet bool = true

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

@description('Database administrator login name')
@minLength(1)
param administratorLogin string = 'ctfd'

@description('Database administrator password. Minimum 8 characters and maximum 128 characters. Password must contain characters from three of the following categories: English uppercase letters, English lowercase letters, numbers, and non-alphanumeric characters.')
@minLength(8)
@secure()
param administratorLoginPassword string

@description('MySQL Type')
@allowed([
  'Development'
  'SmallMedium'
  'BusinessCritical'
])
param mysqlType string = 'Development'

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

@description('Name for Azure Web app. Controls the DNS name of the CTF website')
param webAppName string = 'ctfd-app-${uniqueString(resourceGroup().id)}'

@description('SKU for Azure Container Registry')
var containerRegistrySku = 'Basic'

@description('SKU for Azure Storage Account')
var storageSkuName = 'Standard_LRS'

@description('Account Name for the Azure Storage Account')
var storageAccountName = 'ctfd${uniqueString(resourceGroup().id)}'

@description('Name of Azure Key Vault')
var keyVaultName = 'ctfd-kv-${uniqueString(resourceGroup().id)}'

@description('Name of the key vault secret holding the cache connection string')
var ctfCacheSecretName = 'ctfd-cache-url'

@description('Name of the key vault secret holding the database connection string')
var ctfDatabaseSecretName = 'ctfd-db-url'

@description('Name of the VNet')
var virtualNetworkName = 'ctf-vnet'

@description('Name of the internal resources subnet')
var internalResourcesSubnetName = 'internal_resources_subnet'

@description('Name of the public resources subnet')
var publicResourcesSubnetName = 'public_resources_subnet'

@description('Name of the database resources subnet')
var databaseResourcesSubnetName = 'database_resources_subnet'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'ctf-mi-${uniqueString(resourceGroup().id)}'
  location: resourcesLocation
}

@description('Deploys Azure Log Analytics workspace')
module logAnalyticsModule 'modules/loganalytics.bicep' = {
  name: 'logAnalyticsDeploy'
  params: {
    location: resourcesLocation
  }
}

@description('Deploys Azure Container Registry and build a custom CTFd docker image')
module acrModule 'modules/acr.bicep' = {
  name: 'acrDeploy'
  params: {
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    location: resourcesLocation
    containerRegistrySku: containerRegistrySku
    managedIdentityId: managedIdentity.id
    managedIdentityPrincipalId: managedIdentity.properties.principalId
  }
}

@description('Deploys Virtual Network with two subnets')
module vnetModule 'modules/vnet.bicep' = if (vnet) {
  name: 'vnetDeploy'
  params: {
    location: resourcesLocation
    virtualNetworkName: virtualNetworkName
    internalResourcesSubnetName: internalResourcesSubnetName
    publicResourcesSubnetName: publicResourcesSubnetName
    databaseResourcesSubnetName: databaseResourcesSubnetName
  }
}

module fileStorage 'modules/filestorage.bicep' = {
  name: 'ctfdFileStorage'
  params: {
    internalResourcesSubnetName: internalResourcesSubnetName
    location: resourcesLocation
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    storageSkuName: storageSkuName
    storageAccountName: storageAccountName
    virtualNetworkName: virtualNetworkName
    vnet: vnet
  }
}

module fileStorageAcl 'modules/filestorageAcl.bicep' = {
  name: 'ctfdFileStorageAcl'
  params: {
    location: resourcesLocation
    storageSkuName: storageSkuName
    storageAccountName: storageAccountName
    vnet: vnet
    webAppOutboundIpAdresses: ctfWebAppModule.outputs.outboundIpAdresses
  }
}


@description('Deploys Azure App Service for containers')
module ctfWebAppModule 'modules/webapp.bicep' = {
  name: 'ctfDeploy'
  params: {
    virtualNetworkName: virtualNetworkName
    location: resourcesLocation
    appServicePlanSkuName: appServicePlanSkuName
    keyVaultName: keyVaultName
    ctfCacheSecretName: ctfCacheSecretName
    ctfDatabaseSecretName: ctfDatabaseSecretName
    publicResourcesSubnetName: publicResourcesSubnetName
    webAppName: webAppName
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    acrImageName: acrModule.outputs.acrImage
    registryName: acrModule.outputs.registryName
    managedIdentityClientId: managedIdentity.properties.clientId
    managedIdentityId: managedIdentity.id
    storageAccountName: fileStorage.outputs.storageAccountName
    vnet: vnet
  }
}

@description('Deploys Azure Key Vault')
module akvModule 'modules/keyvault.bicep' = {
  name: 'keyVaultDeploy'
  dependsOn: [ ctfWebAppModule ]
  params: {
    location: resourcesLocation
    readerPrincipalId: managedIdentity.properties.principalId
    internalResourcesSubnetName: internalResourcesSubnetName
    virtualNetworkName: virtualNetworkName
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
    vnet: vnet
    keyVaultName: keyVaultName
    webAppOutboundIpAdresses: ctfWebAppModule.outputs.outboundIpAdresses
  }
}

@description('Deploys Azure Cache for Redis and a Key Vault secret with its connection string')
module redisModule 'modules/redis.bicep' = {
  name: 'redisDeploy'
  params: {
    internalResourcesSubnetName: internalResourcesSubnetName
    virtualNetworkName: virtualNetworkName
    location: resourcesLocation
    vnet: vnet
    ctfCacheSecretName: ctfCacheSecretName
    keyVaultName: akvModule.outputs.keyVaultName
    redisSkuName: redisSkuName
    redisSkuSize: redisSkuSize
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
  }
}

@description('Deploys Azure Database for MySql and a Key Vault secret with its connection string')
module mySqlDbModule 'modules/mysql.bicep' = {
  name: 'mysqlDbDeploy'
  params: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    vnetId: (vnet) ? vnetModule.outputs.virtualNetworkId : ''
    databaseSubnetId: (vnet) ? vnetModule.outputs.databaseResourcesSubnetId : ''
    virtualNetworkName: virtualNetworkName
    location: resourcesLocation
    vnet: vnet
    ctfDbSecretName: ctfDatabaseSecretName
    keyVaultName: akvModule.outputs.keyVaultName
    mysqlWorkloadType: mysqlType
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.logAnalyticsWorkspaceId
  }
}
