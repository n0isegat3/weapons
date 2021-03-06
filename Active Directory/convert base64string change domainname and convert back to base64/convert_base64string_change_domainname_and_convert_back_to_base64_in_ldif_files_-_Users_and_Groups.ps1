#========================================================================
# Date: 13/02/2012
# Author: Jan Marek, Cyber Rangers
#========================================================================

param ($olddomainname = $(Read-Host 'Enter the source domain name, example: oldcontoso'),$olddomainsuffix = $(Read-Host 'Enter the source domain suffix, example: com'),$newdomainname = $(Read-Host 'Enter the destination domain name, example: newcontoso'),$newdomainsuffix = $(Read-Host 'Enter the destination domain suffix, example: com'),$file = $(Read-Host 'Enter the path to the LDF file created by ldifde command in the source domain, example C:\exportedobjects.ldf'),$groupfile = $(Read-Host 'Enter the path to the LDF file containg groups created by ldifde command in the source domain, example C:\exportedgroups.ldf'))
Clear-Host
Write-host "Conversion script for LDF files - Users and Groups - containing base64 encoded values" -foregroundcolor black -BackgroundColor white
Write-host "Script created by Jan Marek, Cyber Rangers" -foregroundcolor magenta
Write-Host

function ConvertFrom-Base64($stringfrom) {
   $bytesfrom  = [System.Convert]::FromBase64String($stringfrom);
   $decodedfrom = [System.Text.Encoding]::UTF8.GetString($bytesfrom);
    return $decodedfrom  
}

function ConvertTo-Base64($stringto) {
   $bytesto  = [System.Text.Encoding]::UTF8.GetBytes($stringto);
   $encodedto = [System.Convert]::ToBase64String($bytesto); 
   return $encodedto;
}

# backup of the current LDF files
Copy-Item $file "$file`.bak"
Write-Host "Backup of $file created to "$file`.bak""
Write-Host
Copy-Item $groupfile "$groupfile`.bak"
Write-Host "Backup of $groupfile created to "$groupfile`.bak""

$allbase64s = (Get-Content $file) | Select-String dn::
foreach ($base64dn in $allbase64s) {
    # write-host $base64dn
    $alldns = $base64dn.ToString().substring(5)
    foreach ($dns in $alldns) {
        # Convert the original base64 string to the text
        $oldstring = convertfrom-base64 $dns
        # Replace the old domain name and suffix with new values
        $decodedall = $oldstring -replace "DC`=$olddomainname`,DC`=$olddomainsuffix", "DC`=$newdomainname`,DC`=$newdomainsuffix"
        
        # Convert the new values to the base64
        $encodedall = convertTo-Base64 $decodedall
        
        $find = $dns
        Write-Host "Finding   $find"
        Write-Host "Decoded   $oldstring"
        Write-Host "Modified  $decodedall"
        Write-Host "Encoded   $encodedall"
        Write-Host
        
        
        # (Get-Content $sourcefile) | Select-String $find
        (Get-Content $file) | Foreach-Object { $_ -replace $find, $encodedall } | Set-Content $file
	(Get-Content $groupfile) | Foreach-Object { $_ -replace $find, $encodedall } | Set-Content $groupfile
        } 
    }
    
Write-Host 'Operation completed'