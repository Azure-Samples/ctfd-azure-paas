@description('Name of the VNet')
param virtualNetworkName string

@description('Name of the VNet')
param resouorcesSubnetName string

@description('Name of the VNet')
param integrationSubnetName string

@description('Location for all resources.')
param location string

var virtualNetworkCIDR = '10.200.0.0/16'
var integrationSubnetCIDR = '10.200.1.0/24'
var resourcesSubnetCIDR = '10.200.2.0/24'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkCIDR
      ]
    }
    subnets: [
      {
        name: resouorcesSubnetName
        properties: {
          addressPrefix: resourcesSubnetCIDR
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: integrationSubnetName
        properties: {
          addressPrefix: integrationSubnetCIDR
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}
