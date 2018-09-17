Connect-AzureRmAccount
#Provide the subscription Id of the subscription where managed disk exists
$sourceSubscriptionId='67ef095c-b712-4ab6-bfb3-94aff8b91787'

#Provide the name of your resource group where managed disk exists
$sourceResourceGroupName='SmileDesignPR'

#Provide the name of the managed disk
$managedDiskName='sdRep001_OsDisk_1_dfe3220f95aa4fdeacb4746fbe999df9'

#Set the context to the subscription Id where Managed Disk exists
Select-AzureRmSubscription -SubscriptionId $sourceSubscriptionId

#Get the source managed disk
$managedDisk= Get-AzureRMDisk -ResourceGroupName $sourceResourceGroupName -DiskName $managedDiskName

#Provide the subscription Id of the subscription where managed disk will be copied to
#If managed disk is copied to the same subscription then you can skip this step
$targetSubscriptionId='5ceff7b9-6e92-4e26-a9f1-777a64f4d099'

#Name of the resource group where snapshot will be copied to
$targetResourceGroupName='myTargetResourceGroupName'

#Set the context to the subscription Id where managed disk will be copied to
#If snapshot is copied to the same subscription then you can skip this step
Select-AzureRmSubscription -SubscriptionId $targetSubscriptionId

$diskConfig = New-AzureRmDiskConfig -SourceResourceId $managedDisk.Id -Location $managedDisk.Location -CreateOption Copy 

#Create a new managed disk in the target subscription and resource group
New-AzureRmDisk -Disk $diskConfig -DiskName $managedDiskName -ResourceGroupName $targetResourceGroupName