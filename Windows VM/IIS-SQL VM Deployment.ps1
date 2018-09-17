
## Login to Azure account
Login-AzureRmAccount 
$ErrorActionPreference = "Stop"

## Get Start Time
$startDTM = (Get-Date)


## Add a List box to select the subscriptions
# pending work????!!!
#
#
#

## Global Variables
$ResourceGroupName = "BestRx-Prod-RG"
$Location = "EastUS"
    
## Storage
$StorageName = "bestrxprodsa"
$StorageType = "Premium_LRS"

## Network
$VNetName = "bestrxprodvnet"
$FrontendSubnetName = "bestrxsubnet1"
$FrontendNic = "bestrx-web01-nic1"
$BackendNic = "bestrx-sql01-nic1"
$FrontendNSG = "bestrx-web01-nsg"
$BackendNSG = "bestrx-sql01-nsg"
$PublicIpFrontend = "bestrx-web01-ip"
$PublicIpBackend = "bestrx-sql01-ip"

## Compute
$FrontendVMName = "bestrx-web01"
$BackendVMName = "bestrx-sql01"
$FrontendComputerName = "bestrx-web01"
$BackendComputerName = "bestrx-sql01"
$FrontendVMSize = "Standard_DS2_v2"
$BackendVMSize = "Standard_DS12_v2"
$FrontendOSDiskName = $FrontendVMName + "OSDisk"
$BackendOSDiskName = $BackendVMName + "OSDisk"

# Resource Group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location

# Storage --- ?Use managed disks
$StorageAccount = New-AzureRmStorageAccount `
                 -ResourceGroupName $ResourceGroupName `
                 -Name $StorageName `
                 -Type $StorageType `
                 -Location $Location

# Network
## Frontend subnet config
$frontendSubnet = New-AzureRmVirtualNetworkSubnetConfig `
                  -Name $FrontendSubnetName `
                  -AddressPrefix 10.0.0.0/24

## Backend subnet config
#$frontendsubnet = New-AzureRmVirtualNetworkSubnetConfig `
                #-Name $FrontendSubnetName `
                #-AddressPrefix 10.0.1.0/24


## Vnet config
$vnet = New-AzureRmVirtualNetwork `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -Name $VNetName `
        -AddressPrefix 10.0.0.0/16 `
        -Subnet $frontendSubnet

## Public IP config
$pip1 = New-AzureRmPublicIpAddress `
       -ResourceGroupName $ResourceGroupName `
       -Location $Location `
       -AllocationMethod Static `
       -Name $PublicIpFrontend

$pip2 = New-AzureRmPublicIpAddress `
       -ResourceGroupName $ResourceGroupName `
       -Location $Location `
       -AllocationMethod Dynamic `
       -Name $PublicIpBackend

## Nic config
$frontendNic = New-AzureRmNetworkInterface `
               -ResourceGroupName $ResourceGroupName `
               -Location $Location `
               -Name $FrontendNic `
               -SubnetId $vnet.Subnets[0].Id `
               -PublicIpAddressId $pip1.Id


$backendNic = New-AzureRmNetworkInterface `
              -ResourceGroupName $ResourceGroupName `
              -Location $Location `
              -Name $BackendNic `
              -SubnetId $vnet.Subnets[0].Id `
              -PublicIpAddressId $pip2.Id

## NSG rules config
# Rule to allow remote desktop (RDP)
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name "RDPRule" -Protocol Tcp `
              -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * `
              -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

$nsgFrontendRule = New-AzureRmNetworkSecurityRuleConfig `
                   -Name myFrontendNSGRule `
                   -Protocol Tcp `
                   -Direction Inbound `
                   -Priority 200 `
                   -SourceAddressPrefix * `
                   -SourcePortRange * `
                   -DestinationAddressPrefix * `
                   -DestinationPortRange 80, 443 `
                   -Access Allow


$nsgBackendRule = New-AzureRmNetworkSecurityRuleConfig `
                  -Name myBackendNSGRule `
                  -Protocol Tcp `
                  -Direction Inbound `
                  -Priority 100 `
                  -SourceAddressPrefix 10.0.0.0/24 `
                  -SourcePortRange * `
                  -DestinationAddressPrefix * `
                  -DestinationPortRange 1433 `
                  -Access Allow

## NSG config
$nsgFrontend = New-AzureRmNetworkSecurityGroup `
               -ResourceGroupName $ResourceGroupName `
               -Location $Location `
               -Name $FrontendNSG `
               -SecurityRules $nsgFrontendRule, $nsgRuleRDP

$nsgBackend = New-AzureRmNetworkSecurityGroup `
              -ResourceGroupName $ResourceGroupName `
              -Location $Location `
              -Name $BackendNSG `
              -SecurityRules $nsgBackendRule, $nsgRuleRDP

## Add NSG to subnets
$vnet = Get-AzureRmVirtualNetwork `
        -ResourceGroupName $ResourceGroupName `
        -Name $VNetName
$frontendSubnet = $vnet.Subnets[0]
#$frontendsubnet = $vnet.Subnets[1]
$frontendSubnetConfig = Set-AzureRmVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet `
  -Name $FrontendSubnetName `
  -AddressPrefix $frontendSubnet.AddressPrefix `
  -NetworkSecurityGroup $nsgFrontend
$backendSubnetConfig = Set-AzureRmVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet `
  -Name $FrontendSubnetName `
  -AddressPrefix $frontendsubnet.AddressPrefix `
  -NetworkSecurityGroup $nsgBackend
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

# Compute
## Frontend VM
$FrontendCred = Get-Credential
$FrontendVirtualMachine = New-AzureRmVMConfig -VMName $FrontendVMName -VMSize $FrontendVMSize
$FrontendVirtualMachine = Set-AzureRmVMOperatingSystem -VM $FrontendVirtualMachine -Windows -ComputerName $FrontendComputerName -Credential $FrontendCred -ProvisionVMAgent -EnableAutoUpdate
$FrontendVirtualMachine = Set-AzureRmVMSourceImage -VM $FrontendVirtualMachine -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version "latest"
$FrontendVirtualMachine = Add-AzureRmVMNetworkInterface -VM $FrontendVirtualMachine -Id $FrontendNic.Id
$FrontendOSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $FrontendOSDiskName + ".vhd"
$FrontendVirtualMachine = Set-AzureRmVMOSDisk -VM $FrontendVirtualMachine -Name $FrontendOSDiskName -VhdUri $FrontendOSDiskUri -CreateOption FromImage -DiskSizeInGB 128
    
## Create the VM in Azure
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $FrontendVirtualMachine

## Install IIS and .Net Framework
Set-AzureRmVMExtension `
    -ResourceGroupName $ResourceGroupName `
    -ExtensionName IIS `
    -VMName $FrontendVMName `
    -Publisher Microsoft.Compute `
    -ExtensionType CustomScriptExtension `
    -TypeHandlerVersion 1.4 `
    -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server,Web-Asp-Net45,NET-Framework-Features"}' `
    -Location $Location

## Backend VM --- SQL Web SKU
$BackendCred = Get-Credential
$BackendVirtualMachine = New-AzureRmVMConfig -VMName $BackendVMName -VMSize $BackendVMSize | `
   Set-AzureRmVMOperatingSystem -Windows -ComputerName $BackendComputerName -Credential $BackendCred -ProvisionVMAgent -EnableAutoUpdate | `
   Set-AzureRmVMSourceImage -PublisherName "MicrosoftSQLServer" -Offer "SQL2017-WS2016" -Skus "SQLDEV" -Version "latest" | `
   Add-AzureRmVMNetworkInterface -Id $BackendNic.Id
    
## Create the VM in Azure
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $BackendVirtualMachine 

# Install SQL IaaS agent
Set-AzureRmVMSqlServerExtension -ResourceGroupName $ResourceGroupName -VMName $BackendVMName -name "SQLIaasExtension" -version "1.2" -Location $Location

## Add Data Disk to the VM
$diskName = $BackendVMName + 'Disk2'
$diskConfig = New-AzureRmDiskConfig -AccountType PremiumLRS -Location $Location -CreateOption Empty -DiskSizeGB 128
$datadisk2 = New-AzureRmDisk -DiskName $diskName -Disk $diskConfig -ResourceGroupName $ResourceGroupName

$vm = Get-AzureRmVM -Name $BackendVMName -ResourceGroupName $ResourceGroupName 
$vm = Add-AzureRmVMDataDisk -VM $vm -Name $diskName -CreateOption Attach -ManagedDiskId $dataDisk2.Id -Lun 1

Update-AzureRmVM -VM $vm -ResourceGroupName $ResourceGroupName



## Deallocate resources
#Remove-AzureRmResourceGroup -Name $ResourceGroupName -Force
#Logout-AzureRmAccount


# Get End Time
$endDTM = (Get-Date)

# Echo Time elapsed
"Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"