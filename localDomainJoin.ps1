$domain = "amctec.local"
$password = "YP#=2qkJ" | ConvertTo-SecureString -asPlainText -Force
$username = "$domain\aniketw" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
Add-Computer -DomainName $domain -Credential $credential -Restart
