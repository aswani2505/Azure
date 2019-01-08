$VM = Get-AzureRmVM -ResourceGroupName SmileDesignPR -VMName SDSQL001
$VM.StorageProfile.ImageReference