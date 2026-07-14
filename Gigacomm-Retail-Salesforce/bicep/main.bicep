targetScope = 'subscription'

@description('Resource group name')
param resourceGroupName string = 'gcr-ae-crm-prd-rg'

@description('Location')
param location string = 'australiasoutheast'

@description('Globally-unique storage account name (lowercase, 3-24 chars)')
param storageAccountName string

@description('Blob container name')
param containerName string = 'sf-backups'

@description('Storage SKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
])
param skuName string = 'Standard_GRS'

@description('Soft delete retention for blobs (days)')
param blobSoftDeleteDays int = 30

@description('Soft delete retention for containers (days)')
param containerSoftDeleteDays int = 30

param tags object

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags:tags
}

module storage './storage.bicep' = {
  name: 'storageRgDeploy'
  scope: rg
  params: {
    location: location
    storageAccountName: storageAccountName
    containerName: containerName
    skuName: skuName
    blobSoftDeleteDays: blobSoftDeleteDays
    containerSoftDeleteDays: containerSoftDeleteDays
    tags:tags
  }
}
