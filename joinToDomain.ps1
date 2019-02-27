$domain = "amctec.dmz"
$password = "Webster2024!" | ConvertTo-SecureString -asPlainText -Force
$username = "$domain\amcadm" 
$credential = New-Object System.Management.Automation.PSCredential($username,$password)
Add-Computer -DomainName $domain -Credential $credential -Restart
