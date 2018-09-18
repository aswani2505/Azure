# C9_VMUsage.ps1 
#
# Version: 12-13-2017
#
# Description: Module to list resource usage versus limites
#
# Prerequisites:
#
# Usage:
#
[CmdletBinding(DefaultParameterSetName="Default")]
param(
  [string]$SubscriptionName
)

$SelSub = select-azurermsubscription -SubscriptionName $SubscriptionName

$Outobj = "1,SubscriptonName,SubscriptionID,Location,Name,CurrentValue,Limit,PercentUsed"
$Outobj
$i = 1

$LocationsWithResources = Get-AzureRmResource |  Select location | Sort-Object -Property location -Unique
$LocationsWithResources = $LocationsWithResources | where {$_.Location -ne 'global' }

$LocationsWithResources[0].Location
foreach ($AzureLocation in $LocationsWithResources) {
  
  $Families = Get-AzureRMVMUsage -Location $AzureLocation.Location 
  foreach ($Family in $Families) {
    $i++
    
    if ($Family.CurrentValue -eq 0) { $PctUsed = 0 } else {$PctUsed = [math]::Round(($Family.CurrentValue/$Family.Limit*100),2) }
    
    $Outobj =  $i.ToString() + "," + `
               $SelSub.Subscription.Name + "," + `
               $SelSub.Subscription.Id + "," + `
               $AzureLocation.Location + "," + `
               $Family.Name.Value + "," + ` 
               $Family.CurrentValue + "," + `
               $Family.Limit + "," + `
               $PctUsed
    $Outobj
  }
}
