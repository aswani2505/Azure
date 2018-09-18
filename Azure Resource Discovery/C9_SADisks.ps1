# C9_SADisks.ps1 
#
# Version: 12-29-2017
#
#
# Description: Module to list all the Disks in the given subscription
#
# Prerequisites:Listed Azure Modules are installed on the machine running the script
#                    -AzureRM - 4.1.0
#
#
# Usage: C9_SADisks.ps1 -SubscriptionName "..."      
#
#
[CmdletBinding(DefaultParameterSetName="Default")]
param(
  [string]$SubscriptionName='PCICAzure1'
)

function GetAttachedVM {
    [cmdletbinding()]
    Param (
        [string]$URI 
    )

    foreach ($VM in $VMs) {    
      if (($VM.StorageProfile.OsDisk.Vhd.Uri) -eq $URI) {return $VM.Name } 

      foreach ($D in $VM.StorageProfile.DataDisks) {

        if ($D.vhd.Uri -eq $URI) {return $VM.Name}
      }
    }
    return $null
}


$SelSub = select-azurermsubscription -SubscriptionName $SubscriptionName

$OutLine = "1,SubscriptionName,SubscriptionID,StorageAccount,Tier,Container,VHDName,LeaseStatus,SizeinGB,VirtualMachine,LastModified"
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
      if ($Blob.BlobType -eq 'PageBlob') {  
        if (($Blob.Name).Split('.')[-1] -eq 'vhd') { 
        
          $BlobURI = $Container.CloudBlobContainer.StorageUri.PrimaryUri.AbsoluteUri +  '/' + $Blob.Name
          $VMName = GetAttachedVM $BlobURI

          $SizeInGB = [int]($Blob.Length/1024/1024/1024)

          $i++
          $OutLine = $i.ToString() + "," + `
                     $SelSub.Subscription.Name + "," + `
                     $SelSub.Subscription.Id + "," + `
                     $ARMSA.StorageAccountName + "," + `
                     $ARMSA.sku.Tier + "," + `
                     $Container.CloudBlobContainer.Name + "," + ` 
                     $Blob.Name + "," + `
                     $Blob.ICloudBlob.Properties.LeaseStatus + "," + `
                     $SizeInGB + "," + `
                     $VMName + "," + `
                     $Blob.LastModified
          $OutLine
        }    
      }
    }
  }
}