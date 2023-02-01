@description('Deploy in VNet')
param vnet bool

@description('Name for Azure Web app')
param webAppName string

@description('Location for all resources.')
param location string

@description('Name of the VNet')
param virtualNetworkName string

@description('Name of the public subnet')
param publicResourcesSubnetName string

@description('Name of azure key vault')
param keyVaultName string

@description('Log Anaytics Workspace Id')
param logAnalyticsWorkspaceId string

@description('App Service Plan SKU name')
param appServicePlanSkuName string

@description('Azure Container Registry Image name')
param acrImageName string

@description('Azure Container Registry name')
param registryName string

@description('Name of the key vault secret holding the cache connection string')
param ctfCacheSecretName string

@description('Name of the key vault secret holding the database connection string')
param ctfDatabaseSecretName string

@description('CTF managed identity client ID')
param managedIdentityClientId string

@description('CTF managed identity ID')
param managedIdentityId string

@description('Server Name for Azure app service')
var appServicePlanName = 'ctfd-server-${uniqueString(resourceGroup().id)}'

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    name: appServicePlanSkuName
  }
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  tags: {}
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': { }
    }
  }
  properties: {
    virtualNetworkSubnetId: (vnet ? resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, publicResourcesSubnetName) : null)
    keyVaultReferenceIdentity: managedIdentityId
    vnetRouteAllEnabled: (vnet ? true : false)
    siteConfig: {
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: managedIdentityClientId
      appSettings: [
        {
          name: 'DATABASE_URL'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${ctfDatabaseSecretName}/)'
        }
        {
          name: 'REDIS_URL'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${ctfCacheSecretName}/)'
        }
        {
          name: 'REVERSE_PROXY'
          value: 'False'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8000'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: '${registryName}.azurecr.io'
        }
      ]
      linuxFxVersion: 'DOCKER|${acrImageName}'
    }
    serverFarmId: appServicePlan.id
  }
}

resource appServiceAppSettings 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webApp
  name: 'logs'
  properties: {
    applicationLogs: {
      fileSystem: {
        level: 'Warning'
      }
    }
    httpLogs: {
      fileSystem: {
        retentionInMb: 40
        retentionInDays: 5
        enabled: true
      }
    }
    failedRequestsTracing: {
      enabled: true
    }
    detailedErrorMessages: {
      enabled: true
    }
  }
}

resource diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${webAppName}-diagnostics'
  scope: webApp
  properties: {
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        categoryGroup: null
        enabled: true
        retentionPolicy: {
          days: 5
          enabled: false
        }
      }
      {
        category: 'AppServiceConsoleLogs'
        categoryGroup: null
        enabled: true
        retentionPolicy: {
          days:5
          enabled: false
        }
      }
      {
        category: 'AppServiceAppLogs'
        categoryGroup: null
        enabled: true
        retentionPolicy: {
          days: 5
          enabled: false
        }
      }
      {
        category: 'AppServiceAuditLogs'
        categoryGroup: null
        enabled: true
        retentionPolicy: {
          days: 5
          enabled: false
        }
      }
      {
        category: 'AppServicePlatformLogs'
        categoryGroup: null
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
