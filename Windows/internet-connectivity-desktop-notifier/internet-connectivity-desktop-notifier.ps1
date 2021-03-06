[cmdletbinding()]
param(
    [int]$balloontiptimeout = 5,
    [int]$testinterval = 10
    )

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$objNotifyIconBad = New-Object System.Windows.Forms.NotifyIcon 
$objNotifyIconBad.Icon = "$PSScriptRoot\warning.ico"
$objNotifyIconBad.BalloonTipText = "Connection Lost" 
$objNotifyIconBad.BalloonTipTitle = "The internet connectivity has been lost!"
$objNotifyIconBad.add_MouseClick($objNotifyIconBad_MouseClick)
$objNotifyIconBad.add_MouseDoubleClick($objNotifyIconBad_MouseDoubleClick)
$objNotifyIconBad_MouseDoubleClick=[System.Windows.Forms.MouseEventHandler]{
    Write-Verbose 'User doubleclicked on Bad Icon'
    $objNotifyIconBad.ShowBalloonTip($balloontiptimeoutmilliseconds)		
}	
$objNotifyIconBad_MouseClick=[System.Windows.Forms.MouseEventHandler]{
    Write-Verbose 'User clicked on Bad Icon'
    $objNotifyIconBad.ShowBalloonTip($balloontiptimeoutmilliseconds)		
}

$objNotifyIconGood = New-Object System.Windows.Forms.NotifyIcon 
$objNotifyIconGood.Icon = "$PSScriptRoot\good.ico"
$objNotifyIconGood.BalloonTipText = "Connection Established" 
$objNotifyIconGood.BalloonTipTitle = "The internet connectivity has been established!"
$objNotifyIconGood.add_MouseClick($objNotifyIconGood_MouseClick)
$objNotifyIconGood.add_MouseDoubleClick($objNotifyIconGood_MouseDoubleClick)
$objNotifyIconGood_MouseDoubleClick=[System.Windows.Forms.MouseEventHandler]{
    Write-Verbose 'User doubleclicked on Good Icon'
    $objNotifyIconGood.ShowBalloonTip($balloontiptimeoutmilliseconds)
}	
$objNotifyIconGood_MouseClick=[System.Windows.Forms.MouseEventHandler]{
    Write-Verbose 'User clicked on Good Icon'
    $objNotifyIconGood.ShowBalloonTip($balloontiptimeoutmilliseconds)
}

$i = '0'
$balloontiptimeoutmilliseconds = $balloontiptimeout*1000

New-EventLog -LogName Application -Source 'JM Internet Connectivity Notifier' -ErrorAction SilentlyContinue

Write-EventLog -LogName Application -Source 'JM Internet Connectivity Notifier' -EntryType Information -EventId 1 -Message 'Notifier Started.'

switch (Test-NetConnection -InformationLevel Quiet) {
$true {$state = 1;$objNotifyIconGood.Visible = $True;$objNotifyIconGood.ShowBalloonTip($balloontiptimeoutmilliseconds);Write-EventLog -LogName Application -Source 'JM Internet Connectivity Notifier' -EntryType Information -EventId 2 -Message "The internet connectivity has been established!"}
$false {$state = 0;$objNotifyIconBad.Visible = $True;$objNotifyIconBad.ShowBalloonTip($balloontiptimeoutmilliseconds);Write-EventLog -LogName Application -Source 'JM Internet Connectivity Notifier' -EntryType Warning -EventId 2 -Message "The internet connectivity has been lost!"}
default {}
}



do {
    start-sleep -Seconds $testinterval
    if ($(Test-NetConnection -InformationLevel Quiet) -eq $true) {
        write-Verbose 'good'
        if ($state -eq 0) {
            Write-EventLog -LogName Application -Source 'JM Internet Connectivity Notifier' -EntryType Information -EventId 2 -Message "The internet connectivity has been established!"
            $objNotifyIconBad.Visible = $False
            $objNotifyIconGood.Visible = $True
            $objNotifyIconGood.ShowBalloonTip($balloontiptimeoutmilliseconds)
            }
        $state = 1
        } else {
        write-Verbose 'bad'
        if ($state -eq 1) {
            Write-EventLog -LogName Application -Source 'JM Internet Connectivity Notifier' -EntryType Warning -EventId 2 -Message "The internet connectivity has been lost!"
            $objNotifyIconGood.Visible = $False
            $objNotifyIconBad.Visible = $True
            $objNotifyIconBad.ShowBalloonTip($balloontiptimeoutmilliseconds)
            }
        $state = 0
        }
}
while ($i -eq '0')


# usage:
# powershell.exe -executionpolicy unrestricted -sta -file D:\internet-connectivity-desktop-notifier.ps1 -balloontiptimeout 5 -testinterval 10

# problems:
# events on notifyicon events are not working