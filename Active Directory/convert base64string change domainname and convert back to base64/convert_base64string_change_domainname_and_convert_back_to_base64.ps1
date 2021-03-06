# Load System.Windows.Forms assembly
$null = [Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”)
$dataObject = New-Object windows.forms.dataobject

# Variables
$olddomainname = 'old'
$olddomainsuffix = 'cz'
$newdomainname = 'domain'
$newdomainsuffix = 'local'

# Functions
function Get-ClipBoard { 
    Add-Type -AssemblyName System.Windows.Forms 
    $tb = New-Object System.Windows.Forms.TextBox 
    $tb.Multiline = $true 
    $tb.Paste() 
    $tb.Text 
}

function ConvertFrom-Base64($string) {
   $bytes  = [System.Convert]::FromBase64String($string);
   $decoded = [System.Text.Encoding]::UTF8.GetString($bytes);
    return $decoded  
}

function ConvertTo-Base64($string) {
   $bytes  = [System.Text.Encoding]::UTF8.GetBytes($string);
   $encoded = [System.Convert]::ToBase64String($bytes); 
   return $encoded;
}

# Main process
# Load the original base64 string from the clipboard
$fromclipboard = Get-Clipboard
# Convert the original base64 string to the text
$oldstring = convertfrom-base64 $fromclipboard
# Replace the old domain name and suffix with new values
$decodedall = $oldstring -replace "DC`=$olddomainname`,DC`=$olddomainsuffix", "DC`=$newdomainname`,DC`=$newdomainsuffix"

Write-Host $decodedall

# Convert the new values to the base64
$outtoclipboard = convertTo-Base64 $decodedall

# Set the new values to the clipboard
$dataObject.SetData([Windows.Forms.DataFormats]::UnicodeText, $true, $outtoclipboard)
[Windows.Forms.Clipboard]::SetDataObject($dataObject, $true)