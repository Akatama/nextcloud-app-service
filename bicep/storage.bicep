@description('name of the Vnet we will attach our VM to')
param vnetName string

@description('name of the Vnet resource group')
param vnetResourceGroup string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
}

@description('Name base name of the resources')
param resourceBaseName string

param location string = 'Central US'

@description('Sku of the storage account')
param storageAccountSkuName string = 'Standard_LRS'

@description('The kind of storage that the storage account will use. Is limited to General-Purpose V2 for Standard and BlockBlobStorage for Premium')
@allowed([
  'StorageV2'
  'BlockBlobStorage'
])
param storageAccountKind string

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${resourceBaseName}jimmystorage'
  location: location
  sku: {
    name: storageAccountSkuName
  }
  kind: storageAccountKind
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    allowCrossTenantReplication: false
    allowedCopyScope: 'AAD'
    isHnsEnabled: true
    isLocalUserEnabled: true
    isNfsV3Enabled: false
    isSftpEnabled: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: virtualNetwork.properties.subnets[0].id
        }
      ]
    }
    publicNetworkAccess: 'Enabled'
    routingPreference: {
      routingChoice: 'MicrosoftRouting'
    }
    supportsHttpsTrafficOnly: true
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: '${storageAccount.name}/default/${resourceBaseName}-data'  
}

@description('Provide the administrator login name for the MySQL server.')
param administratorLogin string

@description('Provide the administrator login password for the MySQL server.')
@secure()
param administratorLoginPassword string


@description('The tier of the particular SKU. High Availability is available only for GeneralPurpose and MemoryOptimized sku.')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param serverEdition string = 'Burstable'

@description('Server version')
@allowed([
  '5.7'
  '8.0.21'
])
param serverVersion string = '8.0.21'

@description('Availability Zone information of the server. (Leave blank for No Preference).')
param availabilityZone string = ''

@description('High availability mode for a server : Disabled, SameZone, or ZoneRedundant')
@allowed([
  'Disabled'
  'SameZone'
  'ZoneRedundant'
])
param haEnabled string = 'Disabled'

@description('Availability zone of the standby server.')
param standbyAvailabilityZone string = '2'

param storageSizeGB int = 120
param storageIops int = 360
@allowed([
  'Enabled'
  'Disabled'
])
param storageAutogrow string = 'Enabled'

@description('The name of the sku, e.g. Standard_D32ds_v4.')
param databaseSkuName string = 'Standard_B1ms'

param backupRetentionDays int = 7

@allowed([
  'Disabled'
  'Enabled'
])
param geoRedundantBackup string = 'Disabled'

param databaseName string = 'nextcloud'

resource mySQLServer 'Microsoft.DBforMySQL/flexibleServers@2023-06-30' = {
  name: toLower(resourceBaseName)
  location: location
  sku: {
    name: databaseSkuName
    tier: serverEdition
  }
  properties: {
    version: serverVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    availabilityZone: availabilityZone
    highAvailability: {
      mode: haEnabled
      standbyAvailabilityZone: standbyAvailabilityZone
    }
    storage: {
      storageSizeGB: storageSizeGB
      iops: storageIops
      autoGrow: storageAutogrow
    }
    // network: {
    //   delegatedSubnetResourceId: virtualNetwork.properties.subnets[0].id
    //   publicNetworkAccess: 'Enabled'
    // }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
  }
}

resource nextcloud_database 'Microsoft.DBforMySQL/flexibleServers/databases@2023-06-30' = {
  parent: mySQLServer
  name: databaseName
  properties: {
    charset: 'utf8mb4'
    collation: 'utf8mb4_general_ci'

  }
}
