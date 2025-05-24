param location string  = resourceGroup().location
param utcValue string = utcNow()
param prefix string

import * as variables from 'modules/variables.bicep'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: variables.getVNetName(prefix)
  resource subnet 'subnets' existing = {
    name: variables.subnetName
  }
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: variables.getUserAssignedIdentityName(prefix)
}

var saName = 'sa${uniqueString(resourceGroup().id)}'
resource dsTest 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: variables.getDeploymentScriptName(prefix)
  location: location
  identity: {
    type: 'userAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  kind: 'AzurePowerShell'
  properties: {
    forceUpdateTag: utcValue
    azPowerShellVersion: '11.0'
    storageAccountSettings: {
      storageAccountName: saName
    }
    containerSettings: {
      subnetIds: [
        {
          id: vnet::subnet.id
        }
      ]
    }    
    scriptContent: loadTextContent('testPartners.ps1')

    retentionInterval: 'P1D'
    cleanupPreference: 'OnExpiration'
  } 
}

output results array = dsTest.properties.outputs.results

