$oldSub = "Visual Studio Enterprise – MPN"
$cred = Get-Credential

#Login to the account and select the old subscription
Connect-AzureRmAccount
Select-AzureRmSubscription -Subscription Visual Studio Enterprise – MPN

#Move all resources to same RG
$sourceRG = "AzureMigrate"
$destRG = "AzureMigrateRG"
$resources = Get-AzureRmResource -ResourceGroupName $sourceRg | ? {$_.ResourceType -ne "Microsoft.Compute/virtualMachines/extensions"} #VM Extensions are not top level resources, so can't be moved this way, but follows the VM
New-AzureRmResourceGroup -Name $destRG -Location 'East US 2'
Move-AzureRmResource -DestinationResourceGroupName $destRG -ResourceId $resources.ResourceId
Remove-AzureRmResourceGroup $sourceRG

#Remove Key Vault link
$vmName = "TestVM"
$vm = Get-AzureRmVM -ResourceGroupName $destRG -Name $vmName
$vm.OSProfile.Secrets = New-Object -TypeName "System.Collections.Generic.List[Microsoft.Azure.Management.Compute.Models.VaultSecretGroup]"
Update-AzureRmVM -ResourceGroupName $destRG -VM $vm -Debug

#Move subscription
$newSub = "MPN Gold Competency"
$newRG = "AzureMigrate"
$location = "East US 2"
$subscriptionID = Get-AzureRmSubscription -SubscriptionName $newSub
$resources = Get-AzureRmResource -ResourceGroupName $destRg| ? {$_.ResourceType -ne "Microsoft.Compute/virtualMachines/extensions"}
Select-AzureRmSubscription -SubscriptionName $newSub
if (!(Get-AzureRmResourceGroup -Name $newRG -ErrorAction SilentlyContinue)) {
New-AzureRmResourceGroup -Name $newRG -Location $location
}
Select-AzureRmSubscription -SubscriptionName $oldSub
Move-AzureRmResource -DestinationResourceGroupName $newRG -ResourceId $resources.ResourceID -DestinationSubscriptionId $subscriptionID.SubscriptionId
