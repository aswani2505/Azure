$domain = "aniket.test"
$password = "Deme@nor250593" | ConvertTo-SecureString -asPlainText -Force
$username = "$domain\aniketw" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
Add-Computer -DomainName $domain -Credential $credential -Restart
