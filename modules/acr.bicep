@description('Location for all resources.')
param location string

@description('Tier of Azure Container Registry.')
param containerRegistrySku string

@description('Managed Identity Principal Id.')
param managedIdentityPrincipalId string

@description('Managed Identity Id.')
param managedIdentityId string

@description('Log Anaytics Workspace Id')
param logAnalyticsWorkspaceId string

@description('Name for Azure Container Registry')
var containerRegistryName = 'ctfdacr${uniqueString(resourceGroup().id)}'

@description('Name and tag of the custom docker image')
var ctfdImageName = 'ctfd-azure-cert:latest'

resource acrResource 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: containerRegistrySku
  }
  properties: {
    adminUserEnabled: false
  }
}

resource diagnosticsSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${containerRegistryName}-diagnostics'
  scope: acrResource
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

resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: acrResource
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, 'b24988ac-6180-42a0-ab88-20f7382dd24c')
  scope: acrResource
  properties: {
    principalId: managedIdentityPrincipalId
    roleDefinitionId: contributorRoleDefinition.id
    principalType: 'ServicePrincipal'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'buildAndPush'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    timeout: 'PT30M'
    azCliVersion: '2.40.0'
    environmentVariables: [
      {
        name: 'acrName'
        value: containerRegistryName
      }
      {
        name: 'acrResourceGroup'
        secureValue: resourceGroup().name
      }
      {
        name: 'taggedImageName'
        value: ctfdImageName
      }
      {
        name: 'CONTENT'
        value: loadTextContent('../Dockerfile')
      }
      {
        name: 'platform'
        value: 'Linux'
      }
      {
        name: 'initialDelay'
        secureValue: '30s'
      }
    ]
    scriptContent: loadTextContent('../scripts/acrbuild.sh')
    retentionInterval: 'P1D'
  }
}

output acrImage string = '${acrResource.properties.loginServer}/${ctfdImageName}'

output registryName string = containerRegistryName
