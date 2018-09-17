# Login to your Azure account and select the right subscription
Connect-AzureRmAccount
Get-AzureRmSubscription
Select-AzureRmSubscription -Subscription "Visual Studio Enterprise – MPN"

# Enable Azure Keyvault
$rgName = "AzureMigrate"
$location = "East US 2"
Register-AzureRmResourceProvider -ProviderNamespace "Microsoft.KeyVault"

# Create a new Keyvault
$keyVaultName = "AzureMigrateKeyVault"
New-AzureRmKeyVault -Location $location `
    -ResourceGroupName $rgName `
    -VaultName $keyVaultName `
    -EnabledForDiskEncryption

# Add a key to the keyvault
Add-AzureKeyVaultKey -VaultName $keyVaultName `
    -Name "AzureMigratePRkey" `
    -Destination "Software"

# Create a Service Principal in AD
$appName = "AzureMigrateKVApp"
$securePassword = ConvertTo-SecureString -String "Deme@nor250593" -AsPlainText -Force
$app = New-AzureRmADApplication -DisplayName $appName `
    -HomePage "https://azuremigratekvapp.contoso.com" `
    -IdentifierUris "https://contoso.com/azuremigratekvapp" `
    -Password $securePassword
New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId

# Set permissions on your Keyvault
Set-AzureRmKeyVaultAccessPolicy -VaultName $keyvaultName `
    -ServicePrincipalName $app.ApplicationId `
    -PermissionsToKeys "WrapKey" `
    -PermissionsToSecrets "Set"

# Encrypt the VM
$keyVault = Get-AzureRmKeyVault -VaultName $keyVaultName -ResourceGroupName $rgName;
$diskEncryptionKeyVaultUrl = $keyVault.VaultUri;
$keyVaultResourceId = $keyVault.ResourceId;
$keyEncryptionKeyUrl = (Get-AzureKeyVaultKey -VaultName $keyVaultName -Name AzureMigratePRkey).Key.kid;

Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $rgName `
    -VMName "TestVM" `
    -AadClientID $app.ApplicationId `
    -AadClientSecret (New-Object PSCredential "user",$securePassword).GetNetworkCredential().Password `
    -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl `
    -DiskEncryptionKeyVaultId $keyVaultResourceId `
    -KeyEncryptionKeyUrl $keyEncryptionKeyUrl `
    -KeyEncryptionKeyVaultId $keyVaultResourceId