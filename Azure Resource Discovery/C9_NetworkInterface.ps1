# C9_NetworkInterface.ps1 
#
# Version: 12-29-2017
#
# Description: Module to list all the Network Interfaces in the given subscription 
#
# Prerequisites:Listed Azure Modules are installed on the machine running the script
#                    -AzureRM.Network - 4.1.0
#
# Usage: C9_NetworkInterface.ps1 -SubscriptionName <subscription name>      
#
#
[CmdletBinding(DefaultParameterSetName="Default")]
param(
  [string]$SubscriptionName
)


function GetAttachedPublicIP {
  [cmdletbinding()]
  Param ([string]$ID )
  foreach ($IP in $IPs) { 
    if ($IP.ID -eq $ID) {return $IP} 
  }
  return $null
}
 
$SelSub = select-azurermsubscription -SubscriptionName $SubscriptionName
$NICs = Get-AzureRmNetworkInterface
$IPs = Get-AzureRmPublicIpAddress 
  
$Outobj = "1,SubscriptonName,SubscriptionID,Name,ResourceGroupName,Location,VirtualMachine,PrivateIpAddress,PrivateIPAddressAllocationMethod,PublicIPAddress,PublicIPAddressAllocationMethod"
$Outobj
$i = 1

foreach ($NIC in $NICS) {  
  
  $PublicIP = GetAttachedPublicIP $NIC.IpConfigurations.PublicIPAddress.Id
    
  if ($PublicIP -eq $null) { 
    $PublicIPAddress = "N/A"
    $PublicIPAllocationMethod = "N/A"
  } 
  else {
    $PublicIPAddress = $PublicIP.IPaddress
    $PublicIPAllocationMethod = $PublicIP.PublicIpAllocationMethod    
  }

  if($NIC.VirtualMachine.Id -eq $null) {$VM = "N/A"}
  else { $VM = Split-Path -Path $NIC.VirtualMachine.Id -Leaf }

  $i++
  $Outobj =  $i.ToString() + "," + `
             $SelSub.Subscription.Name + "," + `
             $SelSub.Subscription.Id + "," + `
             $NIC.Name + "," + `
             $NIC.ResourceGroupName + "," + `
             $NIC.Location + "," + ` 
             $VM + "," + `
             $NIC.IpConfigurations.PrivateIpAddress + "," + ` 
             $NIC.IpConfigurations.PrivateIpAllocationMethod + "," + ` 
             $PublicIPaddress + "," + ` 
             $PublicIpAllocationMethod
  $Outobj
}