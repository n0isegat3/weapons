$logfilepath = ".\WSUS-Report.log"
New-Item -ItemType File -Path $logfilepath -ErrorAction SilentlyContinue

$gpos = get-gpo -all

foreach ($gpo in $gpos) {

   
   
    #$([xml]$($gpo | get-gporeport -reporttype xml)).gpo.computer.extensiondata | ? {$_.name -eq 'Registry'} | select -ExpandProperty extension | select -ExpandProperty policy | ? {$_.category -eq 'Windows Components/Windows Update'} | ft name,state
    $wucfgarray = $([xml]$($gpo | get-gporeport -reporttype xml)).gpo.computer.extensiondata | ? {$_.name -eq 'Registry'} | select -ExpandProperty extension | select -ExpandProperty policy | ? {$_.category -eq 'Windows Components/Windows Update'}
    $wucfgarraycount = $([xml]$($gpo | get-gporeport -reporttype xml)).gpo.computer.extensiondata | ? {$_.name -eq 'Registry'} | select -ExpandProperty extension | select -ExpandProperty policy | ? {$_.category -eq 'Windows Components/Windows Update'} | measure-object

    if ($wucfgarraycount.count -ge 1) {
        write-host "GPO $($gpo.displayname) contains $($wucfgarraycount.count) Windows Update settings." -ForegroundColor green -BackgroundColor Black
        "GPO $($gpo.displayname) contains $($wucfgarraycount.count) Windows Update settings." | Out-File $logfilepath -Append
        $linkstoarray = $([xml]$($gpo | get-gporeport -reporttype xml)).gpo.linksto.sompath
           if ($linkstoarray.count -ge 1) {
               foreach ($linksto in $linkstoarray ) {
                   write-host "GPO $($gpo.displayname) is linked to $linksto" -ForegroundColor green -BackgroundColor Black
                   "GPO $($gpo.displayname) is linked to $linksto" | Out-File $logfilepath -Append
               }
               } else {
                   write-host "GPO $($gpo.displayname) is not linked to any OU." -ForegroundColor red -BackgroundColor Black
                   "GPO $($gpo.displayname) is not linked to any OU." | Out-File $logfilepath -Append
               }
        foreach ($wucfg in $wucfgarray) {
            Write-Host "Setting Name: $($wucfg.Name)" -ForegroundColor Yellow -BackgroundColor Black
            "Setting Name: $($wucfg.Name)" | Out-File $logfilepath -Append
            Write-Host "Setting State: $($wucfg.State)" -ForegroundColor Yellow -BackgroundColor Black
            "Setting State: $($wucfg.State)" | Out-File $logfilepath -Append
            foreach ($multisetting in $wucfg.Numeric) {
                Write-Host "Setting Name: $($multisetting.name)" -ForegroundColor Yellow -BackgroundColor Black
                "Setting Name: $($multisetting.name)" | Out-File $logfilepath -Append
                Write-Host "Setting Value: $($multisetting.value)" -ForegroundColor Yellow -BackgroundColor Black
                "Setting Value: $($multisetting.value)" | Out-File $logfilepath -Append
                }
            foreach ($multisetting in $wucfg.Checkbox) {
                Write-Host "Setting Name: $($multisetting.name)" -ForegroundColor Yellow -BackgroundColor Black
                "Setting Name: $($multisetting.name)" | Out-File $logfilepath -Append
                Write-Host "Setting State: $($multisetting.State)" -ForegroundColor Yellow -BackgroundColor Black
                "Setting State: $($multisetting.State)" | Out-File $logfilepath -Append
                }
            foreach ($multisetting in $wucfg.DropDownList) {
                Write-Host "Setting Name: $($multisetting.name)" -ForegroundColor Yellow -BackgroundColor Black
                "Setting Name: $($multisetting.name)" | Out-File $logfilepath -Append
                Write-Host "Setting State: $($multisetting.State)" -ForegroundColor Yellow -BackgroundColor Black
                "Setting State: $($multisetting.State)" | Out-File $logfilepath -Append
                foreach ($multivalue in $multisetting.value) {
                    Write-Host "Setting Value: $($multivalue.name)" -ForegroundColor Yellow -BackgroundColor Black
                    "Setting Value: $($multivalue.name)" | Out-File $logfilepath -Append
                    }
                }
            foreach ($multisetting in $wucfg.EditText) {
                Write-Host "Setting Name: $($multisetting.name)" -ForegroundColor Yellow -BackgroundColor Black
                "Setting Name: $($multisetting.name)" | Out-File $logfilepath -Append
                Write-Host "Setting Value: $($multisetting.value)" -ForegroundColor Yellow -BackgroundColor Black
                "Setting Value: $($multivalue.name)" | Out-File $logfilepath -Append
                }
            }
    } else {
        write-host "GPO $($gpo.displayname) does not contain any Windows Update settings." -ForegroundColor red -BackgroundColor Black
        "GPO $($gpo.displayname) does not contain any Windows Update settings." | Out-File $logfilepath -Append
    }
    write-host '---------------------------------------------------------' -ForegroundColor Yellow -BackgroundColor Black
    '---------------------------------------------------------'  | Out-File $logfilepath -Append
}