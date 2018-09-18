# C9_ManagedDisks.ps1 
#
# Version: 12-29-2017
#
#
# Description: Module to list all the Managed Disks in the given subscription
#
# Prerequisites:Listed Azure Modules are installed on the machine running the script
#                    -AzureRM - 4.1.0
#
#
# Usage: C9_ManagedDisks.ps1 -SubscriptionName <subscription name>      
#
#
[CmdletBinding(DefaultParameterSetName="Default")]
param(
  [string]$SubscriptionName
)

function GetAttachedVM {
    [cmdletbinding()]
    Param ([string]$ID)

    foreach ($VM in $VMs) { 
      if ($VM.ID -eq $ID) {
        return $VM.Name
      }
     
    }
    return $null
}

$SelSub = select-azurermsubscription -SubscriptionName $SubscriptionName
$VMs = Get-AzureRmVM
$Disks = Get-AzureRmDisk

$Outobj = "1,SubscriptionName,SubscriptionID,ResourceGroupName,Location,Name,TimeCreated,OSType,DiskSizeGB,VirtualMachine,DiskType,SKU"
$Outobj
$i = 1

foreach ($Disk in $Disks) {    
  if($Disk.OSType -eq $null)  {
     $DiskType = "Data Disk"
  }
  else {
    $DiskType = "OS Disk"
  }
   
  $VM = getattachedVM $Disk.ManagedBy
  $i++
  $Outobj =  $i.ToString() + "," + `
             $SelSub.Subscription.Name + "," + `
             $SelSub.Subscription.Id + "," + `
             $Disk.ResourceGroupName + "," + `
             $Disk.Location + "," + ` 
             $Disk.Name + "," + `
             $Disk.TimeCreated + "," + ` 
             $Disk.OsType + "," + `
             $Disk.DiskSizeGB + "," + ` 
             $VM + "," + ` 
             $DiskType + "," + ` 
             $Disk.sku.Name 
  $Outobj
}