@description('Location for all resources.')
param location string

@description('Name of the VNet')
param virtualNetworkName string

@description('Name of the internal resources subnet')
param internalResourcesSubnetName string

@description('Name of the public resources subnet')
param publicResourcesSubnetName string

@description('Name of the database resources subnet')
param databaseResourcesSubnetName string

@description('CIDR of the virtual network')
var virtualNetworkCIDR = '10.200.0.0/16'

@description('CIDR of the public resources subnet')
var publicResourcesSubnetCIDR = '10.200.1.0/26'

@description('CIDR of the internal resources subnet')
var internalResourcesSubnetCIDR = '10.200.2.0/28'

@description('CIDR of the databse resources subnet')
var databaseResourcesSubnetCIDR = '10.200.3.0/28'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-03-01' = {
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
              name: 'dlg-Microsoft.Web-serverfarms'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
        }
      }
      {
        name: databaseResourcesSubnetName
        properties: {
          addressPrefix: databaseResourcesSubnetCIDR
          delegations: [
            {
              name: 'dlg-Microsoft.DBforMySQL-flexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforMySQL/flexibleServers'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

output virtualNetworkId string = virtualNetwork.id
output databaseResourcesSubnetId string = virtualNetwork.properties.subnets[2].id
