# C9_SAContainerInfo.ps1 
#
# Version: 12-29-2017
#
# Description: Module provides information on all the Storage Account Containers in a subscription
#
# Prerequisites:Listed Azure Modules are installed on the machine running the script
#                    -AzureRM.Storage - 3.1.0
#
# Usage: C9_SAContainerInfo.ps1 -SubscriptionName <subscription name>  -Unit < KB | MB | GB | TB >    
#
#  
[CmdletBinding(DefaultParameterSetName="Default")]
param(
  
    [string]$SubscriptionName,
    [string]$Unit = "GB"
)

$SelSub = select-azurermsubscription -SubscriptionName $SubscriptionName
$ARMSAs = Get-AzureRmStorageAccount

$OutLine = "1,SubscriptonName,StorageAccountName,AzureRegion,SKU,BlobEncryptionEnabled,ContainerName,ContainerLastModified,BlobCount,SpaceUsed$Unit"
$OutLine

$i=1
  Foreach ($ARMSA in $ARMSAs) { 
    $SourceData = Get-AzureRMStorageAccountKey -ResourceGroupName $ARMSA.ResourceGroupName -StorageAccountName $ARMSA.StorageAccountName 
    $StorageKey = $SourceData[0].Value
    $Context = New-AzureStorageContext –StorageAccountName $ARMSA.StorageAccountName –StorageAccountKey $StorageKey
    $Containers = Get-AzureStorageContainer -Context $Context 
    Foreach ($Container in $Containers) {
      $CSize = 0
      $Blobs = Get-AzureStorageBlob -Container $Container.Name -Context $Context
      Foreach ($BLob in $Blobs) {
        $Size = $Blob.Length
        $CSize = $CSize + $Size
      }
  
      if($Unit -eq "TB") {$CSize = $CSize/1024/1024/1024/1024}
      elseif($Unit -eq "GB") {$CSize = $CSize/1024/1024/1024}
      elseif($Unit -eq "MB") {$CSize = $CSize/1024/1024}
      elseif($Unit -eq "KB") {$CSize = $CSize/1024}
      else {$CSize}
 
      if ($ARMSA.Encryption.Services.Blob.Enabled -eq $true) { $BlobEncryptionEnabled = 'Yes' } 
      else {$BlobEncyrptionEnabled = 'No'}

      $i++
      $OutLine = $i.ToString() + "," + `
                 $SelSub.Subscription.Name + "," + `
                 $ARMSA.StorageAccountName + "," + `
                 $ARMSA.Location + "," + `
                 $ARMSA.sku.Name + "," + `
                 $BlobEncryptionEnabled + "," + `
                 $Container.Name + "," + `
                 $Container.LastModified + "," + `
                 $Blobs.Count + "," + `
                 [int]$CSize              
      $OutLine
    }
  }