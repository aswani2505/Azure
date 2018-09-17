Connect-AzureRmAccount

New-AzureRmResourceGroupDeployment -Name WindowsVMDeployment -ResourceGroupName WinRG `
  -TemplateUri https://raw.githubusercontent.com/aswani2505/Azure/master/101-Simple-Windows-VM