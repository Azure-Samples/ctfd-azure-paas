@description('Location for all resources.')
param location string

@description('Name of WebApp to monitor')
var appName = 'CTFd'

@description('Name for Log Analytics Workspace')
var logAnalyticsName = 'ctfd-log-analytics-${uniqueString(resourceGroup().id)}'

@description('Log Retention in days')
var retentionInDays = 30

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: {
    displayName: 'Log Analytics'
    ProjectName: appName
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
