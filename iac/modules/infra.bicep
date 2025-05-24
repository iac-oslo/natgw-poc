param location string = 'norwayeast'
param prefix string
param vnetaddressPrefixes string = '10.9.0.0/24'

import * as variables from 'variables.bicep'

resource pipPrefix 'Microsoft.Network/publicIPPrefixes@2024-05-01' = {
  name: variables.getPipPrefixName(prefix)
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '2'
    '1'
    '3'
  ]
  properties: {
    prefixLength: 30
    publicIPAddressVersion: 'IPv4'
  }
}

resource publicIPs 'Microsoft.Network/publicIPAddresses@2024-05-01' = [for i in range(0, 4): {
  name: '${variables.getPipName(prefix)}-${(i + 1)}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '2'
    '1'
    '3'
  ]
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    publicIPPrefix: {
      id: pipPrefix.id
    }
  }  
}]

resource natGateway 'Microsoft.Network/natGateways@2024-05-01' = {
  name: variables.getNatGatewayName(prefix)
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicIPs[0].id
      }
    ]    
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: variables.getVNetName(prefix)
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetaddressPrefixes
      ]
    }
    enableDdosProtection: false
    subnets: [
      {
        name: variables.subnetName
        properties: {
          addressPrefix: vnetaddressPrefixes
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
          natGateway: {
            id: natGateway.id
          }
          delegations: [
            {
              name: 'Microsoft.ContainerInstance.containerGroups'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: variables.subnetName
}

var saName = 'sa${uniqueString(resourceGroup().id)}'
resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: saName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnet.id
          action: 'Allow'
          state: 'Succeeded'
        }
      ]
      defaultAction: 'Deny'
    }
  }
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: variables.getUserAssignedIdentityName(prefix)
  location: location
}

resource storageFileDataPrivilegedContributor 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '69566ab7-960f-475b-8e7c-b3118f30c6bd' // Storage File Data Privileged Contributor
  scope: tenant()
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount

  name: guid(storageFileDataPrivilegedContributor.id, userAssignedIdentity.id, storageAccount.id)
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    roleDefinitionId: storageFileDataPrivilegedContributor.id
    principalType: 'ServicePrincipal'
  }
}

