Connect-AzureRmAccount

#New-AzureRmResourceGroup -Name WinRG
New-AzureRmResourceGroupDeployment -Name WindowsVMDeployment -ResourceGroupName WinRG `
  -TemplateUri https://raw.githubusercontent.com/aswani2505/Azure/master/Decrypt-Windows-VM



$rgName = "WinRG"
$keyVaultName = "WinKeyVault"
$app = Get-AzureRmADApplication -DisplayName "WinKVApp"

# Encrypt the VM
$keyVault = Get-AzureRmKeyVault -VaultName $keyVaultName -ResourceGroupName $rgName;
$diskEncryptionKeyVaultUrl = $keyVault.VaultUri;
$keyVaultResourceId = $keyVault.ResourceId;
$keyEncryptionKeyUrl = (Get-AzureKeyVaultKey -VaultName $keyVaultName -Name WinPRkey).Key.kid;

Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $rgName `
    -VMName "SimpleWinVM" `
    -AadClientID $app.ApplicationId `
    -AadClientSecret (New-Object PSCredential "user",$securePassword).GetNetworkCredential().Password `
    -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
    -DiskEncryptionKeyVaultId $keyVaultResourceId `
    -KeyEncryptionKeyUrl $keyEncryptionKeyUrl `
    -KeyEncryptionKeyVaultId $keyVaultResourceId