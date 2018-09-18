# C9_SABlobs.ps1 
#
# Version: 12-29-2017
#
# Updates: 
#             - added daysold parameter, cleaned up - 12/29 KMC
#
# Description: Module to list all the Storage Account Blobs in the given subscription, that are older than X days 
#
# Prerequisites:Listed Azure Modules are installed on the machine running the script
#                    -AzureRM.Resources - 3.1.0
#
#
# Usage: C9_SABlobs.ps1 -SubscriptionName <Subscription name> [ -daysold < # of days > ]      
#
#  
  [CmdletBinding(DefaultParameterSetName="Default")]
param(
  [string]$SubscriptionName,
  [int]$DaysOld = 0
)
  
  $SubscriptionName

  $SelSub = select-azurermsubscription -SubscriptionName $SubscriptionName   
  $ARMSAs = Get-AzureRmStorageAccount  
  $BeforeDate = (Get-Date).AddDays(-$DaysOld) 
    
  $OutLine = "1,SubscriptonName,SubscriptionID,StorageAccount,Tier,BlobName,BlobType,BlobSize,LastModified"
  $OutLine 
  
  $i=1
  Foreach ($ARMSA in $ARMSAs) { 
    $SourceData = Get-AzureRMStorageAccountKey -ResourceGroupName $ARMSA.ResourceGroupName -StorageAccountName $ARMSA.StorageAccountName 
    $StorageKey = $SourceData[0].Value
    $Context = New-AzureStorageContext –StorageAccountName $ARMSA.StorageAccountName –StorageAccountKey $StorageKey
    $Containers = Get-AzureStorageContainer -Context $Context 
    Foreach ($Container in $Containers) { 
      $Blobs = Get-AzureStorageBlob -Container $Container.Name -Context $Context
      Foreach ($BLob in $Blobs) { 
        if ( $Blob.LastModified -lt $BeforeDate) {
          $i++
          $OutLine = $i.ToString() + "," + `
                     $SelSub.Subscription.Name + "," + `
                     $SelSub.Subscription.Id + "," + `
                     $ARMSA.StorageAccountName + "," + `
                     $ARMSA.sku.Tier+ "," + $Blob.Name + "," + `
                     $Blob.BlobType + "," + $Blob.Length + "," + `
                     $Blob.LastModified
          $OutLine
        }
      }
    }
  }