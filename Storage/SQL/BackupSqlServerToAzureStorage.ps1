<#
	The sample scripts are not supported under any Microsoft standard support 
	program or service. The sample scripts are provided AS IS without warranty  
	of any kind. Microsoft further disclaims all implied warranties including,  
	without limitation, any implied warranties of merchantability or of fitness for 
	a particular purpose. The entire risk arising out of the use or performance of  
	the sample scripts and documentation remains with you. In no event shall 
	Microsoft, its authors, or anyone Else involved in the creation, production, or 
	delivery of the scripts be liable for any damages whatsoever (including, 
	without limitation, damages for loss of business profits, business interruption, 
	loss of business information, or other pecuniary loss) arising out of the use 
	of or inability to use the sample scripts or documentation, even If Microsoft 
	has been advised of the possibility of such damages 
#>

# 0. Prepare database name and Azure related Name
$ServerInstance = "<Your Server name running the target SQL Database>"
$DatabaseName = "<Target Database Name>"

$AzureResourceGroupName = "<Your Azure Resource Group Name>"
$AzureStorageAccountName = "<Your Azure Storage Account Name>"
$AzureContainerName = "<Your Azure Container Name which is under storage account above>"

$BackupFileName = "<Backup file name>"

Try {
$ErrorActionPreference = 'Stop'

# 1. Login Azure Account
	Login-AzureRmAccount

# 2. Get Azure Storage Acount Key
	$Key = (Get-AzureRmStorageAccountKey -ResourceGroupName $AzureResourceGroupName -Name $AzureStorageAccountName)[0].Value

# 3. Get Azure Storage Container Uri
	$StorageUri = (Get-AzureRmStorageAccount -ResourceGroupName $AzureResourceGroupName -Name $AzureStorageAccountName | Get-AzureStorageContainer | Where-Object { $_.Name -eq $AzureContainerName }).CloudBlobContainer.Uri.AbsoluteUri

	$BackupUri = "$StorageUri/$BackupFileName"

# 4. Connect SqlServer cmdlet
	Import-Module Sqlps -DisableNameChecking 3>$null

# 5. Start backup
	Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query "DROP CREDENTIAL myazure; CREATE CREDENTIAL MYAZURE WITH IDENTITY='$AzureStorageAccountName', SECRET='$Key'; BACKUP DATABASE $DatabaseName TO URL='$BackupUri' WITH CREDENTIAL='myazure';" 

	Write-Host "Done"
} Catch {
	Throw
}
