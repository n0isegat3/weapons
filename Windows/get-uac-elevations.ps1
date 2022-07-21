#requires -RunAsAdministrator

$UserToGetUACFor = $env:USERNAME

function Get-ElevationInfo {
param  (    [DateTime]$Before,    [DateTime]$After,    [string[]]$ComputerName,    $User = '*',    $Privileges = '*',    $Newest = [Int]::MaxValue  )   
$null = $PSBoundParameters.Remove('Privileges')  
$null = $PSBoundParameters.Remove('User')  
$null = $PSBoundParameters.Remove('Newest')      
Get-EventLog -LogName Security -InstanceId 4672 @PSBoundParameters |  ForEach-Object {    
    [PSCustomObject]@{      
        Time = $_.TimeGenerated      
        User = $_.ReplacementStrings[1]      
        Domain = $_.ReplacementStrings[2]      
        Privileges = $_.ReplacementStrings[4]    
    }  
} |  Where-Object Path -like $Privileges |  Where-Object User -like $User |  Select-Object -First $Newest} 

Get-ElevationInfo -User $UserToGetUACFor -Newest 5 |Out-GridView