param location string = 'Central US'

@description('name of the Vnet we will attach our VM and database to')
param vnetName string

@description('Subnet we will attach our VM to')
param vmSubnetName string = 'server'

@description('Subnet we will attach our database to')
param dbSubnetName string = 'database'

@description('Provide Virtual Network Address Prefix')
param vnetAddressPrefix string = '10.1.0.0/16'

@description('Provide VM Subnet Address Prefix')
param vmSubnetPrefix string = '10.1.0.0/24'

@description('Provide Subnet Address Prefix')
param dbSubnetPrefix string = '10.1.1.0/24'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: vmSubnetName
        properties: {
          addressPrefix: vmSubnetPrefix
          serviceEndpoints: [
            {
              locations: [
                location
              ]
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: dbSubnetName
        properties: {
          addressPrefix: dbSubnetPrefix
          delegations: [
            {
              name: 'MySQLflexibleServers'
              properties: {
                serviceName: 'Microsoft.DBforMySQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
}
