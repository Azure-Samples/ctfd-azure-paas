@description('Deploy in VNet')
param vnet bool

@description('Database administrator login name')
@minLength(1)
param administratorLogin string

@description('Database administrator password')
@minLength(8)
@secure()
param administratorLoginPassword string

@description('Database vCores count')
param databaseVCores int

@description('Name of the VNet')
param virtualNetworkName string

@description('Name of the internal resources subnet')
param internalResourcesSubnetName string

@description('Name of the key vault')
param keyVaultName string

@description('Name of the connection string secret')
param ctfDbSecretName string

@description('Location for all resources.')
param location string

@description('Log Anaytics Workspace Id')
param logAnalyticsWorkspaceId string

@description('Server Name for Azure database for MariaDB')
var mariaServerName = 'ctfd-mariadb-${uniqueString(resourceGroup().id)}'

resource mariaDbServer 'Microsoft.DBforMariaDB/servers@2018-06-01' = {
  name: mariaServerName
  location: location
  sku: {
    name: 'GP_Gen5_${databaseVCores}'
    size: '5120'
  }
  properties: {
    createMode: 'Default'
    version: '10.3'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    publicNetworkAccess: (vnet ? 'Disabled' : 'Enabled')
  }

  resource mariadbconfig_char_set 'configurations@2018-06-01' = {
    name: 'character_set_server'
    properties: {
      source: 'user-override'
      value: 'utf8mb4'
    }
  }

  resource mariadbconfig_coallation 'configurations@2018-06-01' = {
    name: 'collation_server'
    properties: {
      source: 'user-override'
      value: 'utf8mb4_unicode_ci'
    }
  }

  resource mariadbconfig_wait_timeout 'configurations@2018-06-01' = {
    name: 'wait_timeout'
    properties: {
      source: 'user-override'
      value: '28800'
    }
  }

  resource allowAllWindowsAzureIps 'firewallRules@2018-06-01' = if (!vnet) {
    name: 'AllowAllWindowsAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }
}

module privateEndpointModule 'privateendpoint.bicep' = if (vnet) {
  name: 'mariaDbPrivateEndpointDeploy'
  params: {
    virtualNetworkName: virtualNetworkName
    subnetName: internalResourcesSubnetName
    resuorceId: mariaDbServer.id
    resuorceGroupId: 'mariadbServer'
    privateDnsZoneName: 'privatelink.mariadb.database.azure.com'
    privateEndpointName: 'mariadb_private_endpoint'
    location: location
  }
}

module cacheSecret 'keyvaultsecret.bicep' = {
  name: 'mariaDbKeyDeploy'
  params: {
    keyVaultName: keyVaultName
    secretName: ctfDbSecretName
    secretValue: 'mysql+pymysql://${administratorLogin}%40${mariaServerName}:${administratorLoginPassword}@${mariaServerName}.mariadb.database.azure.com/ctfd?ssl_ca=/opt/certificates/BaltimoreCyberTrustRoot.crt.pem'
  }
}

resource diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${mariaServerName}-diagnostics'
  scope: mariaDbServer
  properties: {
    logs: [
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
