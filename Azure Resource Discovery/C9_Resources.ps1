# C9_Resources.ps1 
#
# Version: 07-20-2017
#
# Updates:
#
# Description: Module to list all the Disks in the given subscription
#
# Prerequisites:Listed Azure Modules are installed on the machine running the script
#                    -AzureRM.Resources - 4.1.0
#
#
# Usage: C9_Resources.ps1 -SubscriptionName "..."      
#
#
[CmdletBinding(DefaultParameterSetName="Default")]
param(
  [string]$SubscriptionName
)

# code to list azure resources 
  $SelSub = select-azurermsubscription -SubscriptionName $SubscriptionName
  $Resources = Get-AzureRmResource
  
  $Outobj = "1,SubscriptonName,SubscriptionID,ResourceGroupName,Location,ResourceName,Kind,ResourceType"
  $Outobj
  $i = 1
  foreach ($Resource in $Resources) {  
    
    $i++
    $Outobj =  $i.ToString() + "," + `
               $SelSub.Subscription.Name + "," + `
               $SelSub.Subscription.Id + "," + `
               $Resource.ResourceGroupName + "," + `
               $Resource.Location + "," + ` 
               $Resource.ResourceName + "," + `
               $Resource.Kind + "," + ` 
               $Resource.ResourceType 
    $Outobj
    }