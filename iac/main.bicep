targetScope = 'subscription'

param location string = 'norwayeast'
param resourceGroupName string
param prefix string

import * as variables from 'modules/variables.bicep'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module infra 'modules/infra.bicep' = {
  name: 'infra'
  scope: resourceGroup
  params: {
    location: location
    prefix: prefix
  }
}
