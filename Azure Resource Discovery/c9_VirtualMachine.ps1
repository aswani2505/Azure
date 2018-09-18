# C9_VirtualMachine.ps1 
#
# Version: 12-29-2017
#
# Description: provides informatino on all ARM VMs in a subscription
#
# Prerequisites:Listed Azure Modules are installed on the machine running the script
#                    -AzureRM - 4.1.0
#
#
# Usage: C9_VirtualMachine.ps1 -SubscriptionName <Subscription name>      
#
#
[CmdletBinding(DefaultParameterSetName="Default")]
param(
  [string]$SubscriptionName
)
 
$SelSub = select-azurermsubscription -SubscriptionName $SubscriptionName
$VMs = Get-AzureRmVM

$Outobj = "1,SubscriptonName,SubscriptionID,ResourceGroupName,Location,VMName,VMSize,OSType,NIC"
$Outobj
$i = 1

foreach ($VM in $VMs) {  

  $OS = 'N/A'
  if ($VM.OSProfile.WindowsConfiguration -ne $null ) { $OS = 'Windows'} 
  elseif ($VM.OSProfile.LinuxConfiguration -ne $null ) { $OS = 'Linux'} 

  $i++
  $Outobj =  $i.ToString() + "," + `
             $SelSub.Subscription.Name + "," + `
             $SelSub.Subscription.Id + "," + `
             $VM.ResourceGroupName + "," + `
             $VM.Location + "," + ` 
             $VM.Name + "," + `
             $VM.HardwareProfile.VmSize + "," + ` 
             $OS + "," + ` 
             ($VM.NetworkProfile.NetworkInterfaces.id).Split('/')[-1] 
  $Outobj
}