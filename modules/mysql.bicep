@description('Deploy in VNet')
param vnet bool

@description('Database administrator login name')
@minLength(1)
param administratorLogin string

@description('Database administrator password')
@minLength(8)
@secure()
param administratorLoginPassword string

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

@description('MySql Workload Type')
@allowed([
  'Development'
  'SmallMedium'
  'BusinessCritical'
])
param mysqlWorkloadType string

@description('Server Name for Azure database for MySql')
var mysqlServerName = 'ctfd-mysql-${uniqueString(resourceGroup().id)}'

 var tier = mysqlWorkloadType == 'Development' ? 'Burstable' : mysqlWorkloadType == 'SmallMedium' ? 'GeneralPurpose' : 'MemoryOptimized'
 var skuName = mysqlWorkloadType == 'Development' ? 'Standard_B1ms' : mysqlWorkloadType == 'SmallMedium' ? 'Standard_E2ads_v5' : 'Standard_E2ads_v5'
var storageSizeGB = mysqlWorkloadType == 'Development' ? 20 : 128
var iops = mysqlWorkloadType == 'Development' ? 360 : 2000

resource mysqlDbServer 'Microsoft.DBforMySQL/flexibleServers@2023-10-01-preview' = {
  name: mysqlServerName
  location: location
  sku: {
    name: skuName
    tier: tier
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storage: {
      autoGrow: 'Enabled'
      iops: iops
      storageSizeGB: storageSizeGB
    }
    network: {
      publicNetworkAccess: vnet ? 'Disabled' : 'Enabled'
    }

    createMode: 'Default'
    version: '8.0.21'
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
}

resource collationConfiguration 'Microsoft.DBforMySQL/flexibleServers/configurations@2023-06-30' = {
  name: 'collation_server'
  parent: mysqlDbServer
  properties: {
    source: 'user-override'
    value: 'UTF8MB4_UNICODE_CI'
  }
}

resource ctfdDatabase 'Microsoft.DBforMySQL/flexibleServers/databases@2023-06-30' = {
  name: 'ctfd'
  parent: mysqlDbServer
  properties: {
    charset: 'utf8mb4'
    collation: 'utf8mb4_unicode_ci'
  }
}

resource ctdFirewallRule 'Microsoft.DBforMySQL/flexibleServers/firewallRules@2023-06-30' = if (!vnet) {
  name: 'AllowAllAzureServicesAndResourcesWithinAzureIps_2024-5-24_16-27-0'
  parent: mysqlDbServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

module privateEndpointModule 'privateendpoint.bicep' = if (vnet) {
  name: 'sqlDbPrivateEndpointDeploy'
  params: {
    virtualNetworkName: virtualNetworkName
    subnetName: internalResourcesSubnetName
    resuorceId: mysqlDbServer.id
    resuorceGroupId: 'mysqlServer'
    privateDnsZoneName: 'privatelink.mysql.database.azure.com'
    privateEndpointName: 'sqlserverdb_private_endpoint'
    location: location
  }
}


module sqlSecret 'keyvaultsecret.bicep' = {
  name: 'sqlDbKeyDeploy'
  params: {
    keyVaultName: keyVaultName
    secretName: ctfDbSecretName
    secretValue: 'mysql+pymysql://${administratorLogin}@${mysqlServerName}:${administratorLoginPassword}@${mysqlServerName}.mysql.database.azure.com/ctfd?ssl_ca=/opt/certificates/DigiCertGlobalRootCA.crt.pem'
  }
}

resource diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${mysqlServerName}-diagnostics'
  scope: mysqlDbServer
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