@description('Location for all resources.')
param location string

@description('Name of the VNet')
param virtualNetworkName string

@description('Name of the internal resources subnet')
param internalResourcesSubnetName string

@description('Name of the public resources subnet')
param publicResourcesSubnetName string

@description('CIDR of the virtual network')
param virtualNetworkCIDR string

@description('CIDR of the public resources subnet')
param publicResourcesSubnetCIDR string

@description('CIDR of the internal resources subnet')
var internalResourcesSubnetCIDR = '10.200.2.0/28'

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
        name: internalResourcesSubnetName
        properties: {
          addressPrefix: internalResourcesSubnetCIDR
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: publicResourcesSubnetName
        properties: {
          addressPrefix: publicResourcesSubnetCIDR
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

