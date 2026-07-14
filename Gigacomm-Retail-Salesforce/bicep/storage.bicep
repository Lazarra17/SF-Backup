targetScope = 'resourceGroup'

param location string
param storageAccountName string
param containerName string
param skuName string
param blobSoftDeleteDays int
param containerSoftDeleteDays int
param tags object

// Prefixes used by lifecycle rules (must match your blob paths)
param dailyPrefix string = 'salesforce-backups/daily/'
param weeklyPrefix string = 'salesforce-backups/weekly/'
param monthlyPrefix string = 'salesforce-backups/monthly/'
param yearlyPrefix string = 'salesforce-backups/yearly/'

resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: { name: skuName }
  tags: tags
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    accessTier: 'Hot'
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: { enabled: true }
        file: { enabled: true }
      }
    }
  }
}

resource blobSvc 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: sa
  properties: {
    isVersioningEnabled: true
    deleteRetentionPolicy: {
      enabled: true
      days: blobSoftDeleteDays
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: containerSoftDeleteDays
    }
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: containerName
  parent: blobSvc
  properties: {
    publicAccess: 'None'
  }
}

resource lifecycle 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = {
  name: 'default'
  parent: sa
  properties: {
    policy: {
      rules: [
        // DAILY: Hot tier, delete after 30 days
        {
          name: 'daily-30d-hot'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: [ 'blockBlob' ]
              prefixMatch: [ dailyPrefix ]
            }
            actions: {
              baseBlob: {
                delete: {
                  daysAfterModificationGreaterThan: 30
                }
              }
            }
          }
        }

        // WEEKLY: Cool tier immediately, delete after ~3 months (90 days)
        {
          name: 'weekly-3mo-cool'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: [ 'blockBlob' ]
              prefixMatch: [ weeklyPrefix ]
            }
            actions: {
              baseBlob: {
                tierToCool: {
                  daysAfterModificationGreaterThan: 0
                }
                delete: {
                  daysAfterModificationGreaterThan: 90
                }
              }
            }
          }
        }

        // MONTHLY: Archive tier immediately, delete after 1 year
        {
          name: 'monthly-1y-archive'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: [ 'blockBlob' ]
              prefixMatch: [ monthlyPrefix ]
            }
            actions: {
              baseBlob: {
                tierToArchive: {
                  daysAfterModificationGreaterThan: 0
                }
                delete: {
                  daysAfterModificationGreaterThan: 365
                }
              }
            }
          }
        }

        // YEARLY: Archive tier immediately, delete after 10 years
        {
          name: 'yearly-10y-archive'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: [ 'blockBlob' ]
              prefixMatch: [ yearlyPrefix ]
            }
            actions: {
              baseBlob: {
                tierToArchive: {
                  daysAfterModificationGreaterThan: 0
                }
                delete: {
                  daysAfterModificationGreaterThan: 3650
                }
              }
            }
          }
        }
      ]
    }
  }
}

output storageAccountName string = sa.name
output containerNameOut string = containerName
