using './main.bicep'

param resourceGroupName = 'gcr-ae-retail-prd-rg'
param location = 'australiasoutheast'
param containerName = 'sf-backups'
param blobSoftDeleteDays = 30
param containerSoftDeleteDays = 30
param storageAccountName = 'gcraesfbackupprd'

param tags = {
  Environment: 'prd'
  Owner: 'gigacomm'
  Purpose: 'retail'
}
