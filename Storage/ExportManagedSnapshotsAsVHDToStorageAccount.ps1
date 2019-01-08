#Provide the subscription Id of the subscription where snapshot is created
$subscriptionId = "5ceff7b9-6e92-4e26-a9f1-777a64f4d099"

#Provide the name of your resource group where snapshot is created
$resourceGroupName ="aniket-test-rg"

#Provide the snapshot name 
$snapshotName = "aniket-ws-snapshot01"

#Provide Shared Access Signature (SAS) expiry duration in seconds e.g. 3600.
#Know more about SAS here: https://docs.microsoft.com/en-us/azure/storage/storage-dotnet-shared-access-signature-part-1
$sasExpiryDuration = "36000"

#Provide storage account name where you want to copy the snapshot. 
$storageAccountName = "aniketsa"

#Name of the storage container where the downloaded snapshot will be stored
$storageContainerName = "vhds"

#Provide the key of the storage account where you want to copy snapshot. 
$storageAccountKey = 'gysKD4ecV6wA3TdCGH8UFuwTYvkV/xdswrA1y4g/1dNO7TIjRtsUa2arZLD8qE12mihUmDk7mcrMeKb9EblOQA=='

#Provide the name of the VHD file to which snapshot will be copied.
$destinationVHDFileName = "aniket-ws.vhd"


# Set the context to the subscription Id where Snapshot is created
Select-AzureRmSubscription -SubscriptionId $SubscriptionId

#Generate the SAS for the snapshot 
$sas = Grant-AzureRmSnapshotAccess -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName  -DurationInSecond $sasExpiryDuration -Access Read 
 
#Create the context for the storage account which will be used to copy snapshot to the storage account 
$destinationContext = New-AzureStorageContext –StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey  

#Copy the snapshot to the storage account 
Start-AzureStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestContainer $storageContainerName -DestContext $destinationContext -DestBlob $destinationVHDFileName