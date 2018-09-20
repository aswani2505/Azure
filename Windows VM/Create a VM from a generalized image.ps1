# Login to the azure account and select the subscription
Connect-AzureRmAccount
Select-AzureRmSubscription -Subscription 'Nifast CSP'

# Create a managed image from the uploaded vhd
$rgName = 'NifastNAVInfra'
$location = "Central US" 
$imageName = "nifnavshimage"
$urlOfUploadedImageVhd = "https://nfnavdr2sa.blob.core.windows.net/vhds/NifastBrazilHostAug24-osDisk.6c63f63c-9a71-4299-9ad2-7e0e580b366f.vhd"
$imageConfig = New-AzureRmImageConfig `
   -Location $location
$imageConfig = Set-AzureRmImageOsDisk `
   -Image $imageConfig `
   -OsType Windows `
   -OsState Generalized `
   -BlobUri $urlOfUploadedImageVhd `
   -DiskSizeGB 127
New-AzureRmImage `
   -ImageName $imageName `
   -ResourceGroupName $rgName `
   -Image $imageConfig

# Create the VM
$resourceGroupName = "NifastNAVPR"
$locationName = "East US 2"
$myVnet = 'nifnavprnet'
$mySubnet = 'Subnet1'
$myNSG = 'nifnavsgsh'
$myPIP = 'nifnavprsh100ip'
New-AzureRmVm `
    -ResourceGroupName "NifastNAVPR" `
    -Name "nifnavprsh100" `
    -ImageName $imageName `
    -Location "East US 2" `
    -VirtualNetworkName "nifnavprnet" `
    -SubnetName "Subnet1" `
    -SecurityGroupName "nifnavsgsh" `
    -PublicIpAddressName "nifnavprsh100ip" `
    -OpenPorts 3389