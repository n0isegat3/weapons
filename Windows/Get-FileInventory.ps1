[cmdletbinding()]
param()

Clear-Host
# Copyright:
Write-host "INVENTORY FILES ON COMPUTERS POWERSHELL SCRIPT" -foregroundcolor white -BackgroundColor DarkGray
Write-host "....................1.0.0.4..................." -foregroundcolor white -BackgroundColor DarkGray
Write-Host
Write-host "Script Created by Jan Marek, Cyber Rangers" -foregroundcolor white -BackgroundColor red
write-host "This script does inventory of specific files on defined computers."  -foregroundcolor white -BackgroundColor black
write-host "Source list of computers can be either Active Directory or TXT file."  -foregroundcolor white -BackgroundColor black
Write-Host

# Load Assemblies
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices")

# Messaging
$message = "Confirm your selection please. "
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Entered informations are wrong. Enter again."
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Entered informations are correct. Procceed ahead."
$quit = New-Object System.Management.Automation.Host.ChoiceDescription "&Quit", "Exit the script."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $quit)

# variables
$global:inventoryguid = [guid]::NewGuid()

# Functions
function do-inventory($devicelist,$filter) {
               $mainstarttime = Get-Date
               $devices = $devicelist
               $filefilter = $filter

               Write-Host "Those " $devices.count " device(s) will be inventoried:" -ForegroundColor Yellow
               $devices
               write-host 
               Read-Host 'Press ENTER to continue...'
               write-host

               $reportdata =@()
               foreach ($device in $devices) {
               write-host
               Write-Host "Testing connection to " $device "..." -ForegroundColor Yellow
               Clear-Variable ErrDeviceConnection -ErrorAction SilentlyContinue
                Invoke-Command -ComputerName $device -ScriptBlock {} -ErrorVariable ErrDeviceConnection -ErrorAction SilentlyContinue
                if ($ErrDeviceConnection) {
                        $pcobject = @{"PSComputerName" = $device}
                        $offlinepc = New-Object -TypeName PSObject -Property $pcobject
                        $reportdata += $offlinepc
                        Write-host ("Connection to the device $device failed. Error output is:") -BackgroundColor yellow -ForegroundColor red
                        Write-host $ErrDeviceConnection -BackgroundColor red -ForegroundColor white
                  Clear-Variable ErrDCConnection -ErrorAction SilentlyContinue
                  continue # go to another foreach cycle
                  } else {
                  write-host "Connection test to " $device " was successful." -ForegroundColor Green -BackgroundColor black
                  $starttime = Get-Date
                  write-host "Starting inventory on device " $device " at " $starttime
                    $files = Invoke-Command  -ArgumentList $FileFilter,$starttime,$global:inventoryguid -ComputerName $device -ScriptBlock {
                    If (Get-EventLog -LogName Application -Source "File Inventory PoSH Script") {write-host 'EventLog source exists.'} else {
                        New-EventLog -LogName Application -Source "File Inventory PoSH Script"
                        }
    
                  Write-EventLog -LogName Application -Source "File Inventory PoSH Script" -EntryType Information -EventId 1 -Message "GUID: $($args[2]) `nInventory started."
                        $drives = Get-WmiObject -Class win32_logicaldisk -Filter drivetype=3 | Select-Object -ExpandProperty deviceid
                        write-host "Found " $drives.count " drive(s) on " $env:COMPUTERNAME
                       foreach ($driveletter in $drives) {  
                      
                      
                       write-host "Inventory of " $args[0] " started on drive " $driveletter "."                
                       Write-EventLog -LogName Application -Source "File Inventory PoSH Script" -EntryType Information -EventId 1 -Message "GUID: $($args[2]) `nInventory of $($args[0]) started on drive $driveletter ."
                       
                       
                       $invjob = Start-Job -argumentlist $args[0],$driveletter,$args[2] -scriptblock {
                       write-verbose "`$searchpath is $searchpath"
                       write-verbose "`$searchfilter is $searchfilter"
                        $searchpath = $args[1]
                       $searchfilter = $args[0]
                       $localsearcherror = @()
                       gci -File -Recurse -Include $searchfilter -Path $searchpath`\ -ErrorAction SilentlyContinue -ErrorVariable +localsearcherror | 
                       #select -First 100 | ##### THIS LINE IS ONLY FOR TEST PURPOSES!!!!! #####################################################
                       select `
                       Name, `
                       FullName,`
                       Length,`
                       Extension,`
                       CreationTime,`
                       CreationTimeUTC,`
                       LastAccessTime,`
                       LastAccessTimeUTC,`
                       LastWriteTime,`
                       LastWriteTimeUTC,`
                       Attributes,`
                       @{n='FileOwner';e={(get-acl $_.fullname).Owner}}

                       $localerrorcount = $localsearcherror.count
                     If ($localerrorcount -gt 0) {
                        Write-EventLog -LogName Application -Source "File Inventory PoSH Script" -EntryType Information -EventId 2 -Message "GUID: $($args[2]) `nThere was $localerrorcount search errors on $searchpath ."
                        } else {
                        Write-EventLog -LogName Application -Source "File Inventory PoSH Script" -EntryType Information -EventId 2 -Message "GUID: $($args[2]) `nNo search errors on $searchpath ."
                        }
                        

                       } # end job

                       while ($invjob.state -eq 'running') {
                            $runinvtime = $(Get-Date) - $($args[1])
                            $runningcount = (Receive-Job $invjob -Keep).count
                            Write-Host $(Get-Date) " Inventory running ($env:computername, $driveletter). Found $runningcount file(s). Total run time $($runinvtime.ToString().substring(0,8)). Waiting 10 seconds..." -ForegroundColor Green -BackgroundColor Black
                         Start-Sleep -Seconds 10
                            }

                       If ($invjob.State -eq 'completed') {
                            Receive-Job $invjob
                            } else {
                            write-host 'Error during inventory. Job state is ' $invjob.State
                            }

                       Write-Host 'Messages from inventory:'
                       Get-EventLog -LogName Application -Source "File Inventory PosH script" -Message "*$($args[2])*" | Format-Table InstanceID,Message -AutoSize
                       Write-Host
                        
                       } # end foreach
                       Write-EventLog -LogName Application -Source "File Inventory PoSH Script" -EntryType Information -EventId 99 -Message "Inventory completed."
                       } # end invoke-command
                       Write-Host "Found " $files.count " " $filefilter " files."
                       $endtime = Get-Date
                       $invtime = $endtime - $starttime
                       write-host "Inventory on device " $device " completed at " $endtime " (inventory time $($invtime.ToString().substring(0,8)))."-ForegroundColor Green -BackgroundColor Black

                       $reportdata += $files
               } # end if
               }

               ##### END OF INVENTORY

               $mainendtime = Get-Date
               $mainruntime = $mainendtime - $mainstarttime
               write-host "Inventory of all devices completed at " $mainendtime " (inventory time $($mainruntime.ToString().substring(0,8)))."-ForegroundColor Green -BackgroundColor Black


               do {$reportfile = Get-SaveFile -initialDirectory $env:USERPROFILE\desktop} until ($reportfile)
               


               $reportdata | select `
                       PSComputerName,`
                       Name, `
                       FullName,`
                       Length,`
                       Extension,`
                       CreationTime,`
                       CreationTimeUTC,`
                       LastAccessTime,`
                       LastAccessTimeUTC,`
                       LastWriteTime,`
                       LastWriteTimeUTC,`
                       Attributes,`
                       FileOwner | Export-csv $reportfile -Delimiter ',' -NoTypeInformation -Encoding UTF8

}

function do-localinventory($filter) {
               $mainstarttime = Get-Date
               $filefilter = $filter

               Write-Host "Local computer will be inventoried." -ForegroundColor Yellow
               Read-Host 'Press ENTER to continue...'
               write-host

               $reportdata =@()
               
               write-host

                  $starttime = Get-Date 
                  write-host "Starting inventory on device LOCAL computer at " $starttime
                    
                        $drives = Get-WmiObject -Class win32_logicaldisk -Filter drivetype=3 | select -ExpandProperty deviceid
                        write-host "Found " $drives.count " drive(s) on LOCALHOST" # nefunguje
                       foreach ($driveletter in $drives) {  
                       write-host "Inventory of " $FileFilter " started on drive " $driveletter "."                
                       
                       $invjob = Start-Job -argumentlist $filefilter,$driveletter -scriptblock {
                       $searchpath = $args[1]
                       $searchfilter = $args[0]
                       write-verbose "`$searchpath is $searchpath"
                       write-verbose "`$searchfilter is $searchfilter"
                       gci -Recurse -Include $searchfilter -Path $searchpath`\ -ErrorAction 'SilentlyContinue'| 
                       #select -First 100 | ##### THIS LINE IS ONLY FOR TEST PURPOSES!!!!! #####################################################
                       select `
                       Name, `
                       FullName,`
                       Length,`
                       Extension,`
                       CreationTime,`
                       CreationTimeUTC,`
                       LastAccessTime,`
                       LastAccessTimeUTC,`
                       LastWriteTime,`
                       LastWriteTimeUTC,`
                       Attributes,`
                       @{n='FileOwner';e={(get-acl $_.fullname).Owner}}

                     

                       } # end job

                       while ($invjob.state -eq 'running') {
                            $runinvtime = $(Get-Date) - $starttime
                            $runningcount = (Receive-Job $invjob -Keep).count
                            Write-Host $(Get-Date) " Inventory running (LOCALHOST, $driveletter). Found $runningcount file(s). Total run time $($runinvtime.ToString().substring(0,8)). Waiting 10 seconds..." -ForegroundColor Green -BackgroundColor Black
                            Start-Sleep -Seconds 10
                            }

                       If ($invjob.State -eq 'completed') {$files = Receive-Job $invjob} else {write-host 'Error during inventory. Job state is ' $invjob.State;exit}


                       } # end foreach
                       
                       Write-Host "Found " $files.count " " $filefilter " files."
                       $endtime = Get-Date
                       $invtime = $endtime - $starttime
                       write-host "Inventory on localhost completed at " $endtime " (inventory time $($invtime.ToString().substring(0,8)))."-ForegroundColor Green -BackgroundColor Black

                       $reportdata += $files
               
               

               ##### END OF INVENTORY

               $mainendtime = Get-Date
               $mainruntime = $mainendtime - $mainstarttime
               write-host "Inventory of local device completed at " $mainendtime " (inventory time $($mainruntime.ToString().substring(0,8)))."-ForegroundColor Green -BackgroundColor Black


               do {$reportfile = Get-SaveFile -initialDirectory $env:USERPROFILE\desktop} until ($reportfile)
               


               $reportdata | select `
                       PSComputerName,`
                       Name, `
                       FullName,`
                       Length,`
                       Extension,`
                       CreationTime,`
                       CreationTimeUTC,`
                       LastAccessTime,`
                       LastAccessTimeUTC,`
                       LastWriteTime,`
                       LastWriteTimeUTC,`
                       Attributes,`
                       FileOwner | Export-csv $reportfile -Delimiter ',' -NoTypeInformation -Encoding UTF8

}

Function Get-SaveFile($initialDirectory) {
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
Out-Null

$SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
$SaveFileDialog.initialDirectory = $initialDirectory
$SaveFileDialog.filter = "CSV files (*.CSV)| *.csv"
$SaveFileDialog.ShowDialog() | Out-Null
$SaveFileDialog.Title = 'Save as - report file'
$SaveFileDialog.filename
} 

Function Get-OpenFile($initialDirectory) {
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
Out-Null

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.initialDirectory = $initialDirectory
$OpenFileDialog.filter = "Text Files (*.txt)| *.txt"
$OpenFileDialog.ShowDialog() | Out-Null
$OpenFileDialog.Title = 'Open - source text file'
$OpenFileDialog.filename
}

function getdcname {
    Do  {
        $DomainControllerInfo = Browse-ActiveDirectory "Select the Active Directory Domain Controller for Query"
        If ($DomainControllerInfo -eq $false) {exit}
        Clear-Variable DomainControllerReturn -ErrorAction SilentlyContinue
        $DomainControllerReturn = $DomainControllerInfo.cn
        }
    Until ($DomainControllerReturn)
    If ($DomainControllerReturn -eq $false) {exit}
    [console]::ForegroundColor = "yellow"
    $message = ("A Domain Contoller Host Name is: " + $DomainControllerReturn)
    [console]::ResetColor()
    do 
    {
    # Ask for confirmation of entered value(s)
    $promptResult = $host.ui.PromptForChoice($null, $message, $options, 0) 
    # write-host

    switch ($promptResult)
    {
        1   {# NO = ask again
            getdcname
            }
    
        2   {# QUIT = shutdown the script
            exit
            }           
        }
    }
until ($promptResult -eq 0)
Return $DomainControllerReturn
}

function getfulldomainname {
$DomainNameReturn = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
$message = ("A Domain Name is: " + $DomainNameReturn)
    [console]::ResetColor()
    do 
    {
    # Ask for confirmation of entered value(s)
    $promptResult = $host.ui.PromptForChoice($null, $message, $options, 0) 
    # write-host

    switch ($promptResult)
    {
        1   {# NO = ask again
            getfulldomainname
            }
    
        2   {# QUIT = shutdown the script
            exit
            }           
        }
    }
until ($promptResult -eq 0)
    Return $DomainNameReturn
}

function getldapou {
    $LDAPUserOU = Browse-ActiveDirectory "Select the OU of computers' objects..."
    If ($LDAPUserOU -eq $false) {exit}
    #$LDAPUserOUReturn = $LDAPUserOU.path
    $LDAPUserOUReturn = $LDAPUserOU.distinguishedname
    [console]::ForegroundColor = "yellow"
    $message = ("The OU of computers' objects is: " + $LDAPUserOU.distinguishedname)
    [console]::ResetColor()
    do 
    {
    # Ask for confirmation of entered value(s)
    $promptResult = $host.ui.PromptForChoice($null, $message, $options, 0) 
    # write-host

    switch ($promptResult)
    {
        1   {# NO = ask again
            getldapou
            }
    
        2   {# QUIT = shutdown the script
            exit
            }           
        }
    }
until ($promptResult -eq 0)
    Return $LDAPUserOUReturn
}

# Browse-ActiveDirectory
$root = (new-object system.directoryservices.directoryEntry)
Function Browse-ActiveDirectory { 
  param ($dialogtext) 

  # Try to connect to the Domain root 

  &{trap {throw "$($_)"};[void]$Root.get_Name()} 

  # Make the form 

  $form = new-object Windows.Forms.form    
  $form.Size = new-object System.Drawing.Size @(800,600)    
  $form.text = $dialogtext   

  # Make TreeView to hold the Domain Tree 

  $TV = new-object windows.forms.TreeView 
  $TV.Location = new-object System.Drawing.Size(10,30)   
  $TV.size = new-object System.Drawing.Size(770,470)   
  $TV.Anchor = "top, left, right"     

  # Add the Button to close the form and return the selected DirectoryEntry 
  
  $btnSelect = new-object System.Windows.Forms.Button  
  $btnSelect.text = "Select" 
  $btnSelect.Location = new-object System.Drawing.Size(710,510)   
  $btnSelect.size = new-object System.Drawing.Size(70,30)   
  $btnSelect.Anchor = "Bottom, right"   

  # If Select button pressed set return value to Selected DirectoryEntry and close form 

  $btnSelect.add_Click({ 
    $script:Return = new-object system.directoryservices.directoryEntry("LDAP://$($TV.SelectedNode.text)")  
    $form.close() 
  }) 

  # Add Cancel button  

  $btnCancel = new-object System.Windows.Forms.Button  
  $btnCancel.text = "Cancel" 
  $btnCancel.Location = new-object System.Drawing.Size(630,510)   
  $btnCancel.size = new-object System.Drawing.Size(70,30)   
  $btnCancel.Anchor = "Bottom, right"   

  # If cancel button is clicked set returnvalue to $False and close form 

  $btnCancel.add_Click({$script:Return = $false ; $form.close()}) 

  # Create a TreeNode for the domain root found 

  $TNRoot = new-object System.Windows.Forms.TreeNode("Root") 
  $TNRoot.Name = $root.name 
  $TNRoot.Text = $root.distinguishedName 
  $TNRoot.tag = "NotEnumerated" 

  # First time a Node is Selected, enumerate the Children of the selected DirectoryEntry 

  $TV.add_AfterSelect({ 
    if ($this.SelectedNode.tag -eq "NotEnumerated") { 

      $de = new-object system.directoryservices.directoryEntry("LDAP://$($this.SelectedNode.text)") 

      # Add all Children found as Sub Nodes to the selected TreeNode 

      $de.get_Children() |  
      foreach { 
        $TN = new-object System.Windows.Forms.TreeNode 
        $TN.Name = $_.name 
        $TN.Text = $_.distinguishedName 
        $TN.tag = "NotEnumerated" 
        $this.SelectedNode.Nodes.Add($TN) 
      } 

      # Set tag to show this node is already enumerated 
  
      $this.SelectedNode.tag = "Enumerated" 
    } 
  }) 

  # Add the RootNode to the Treeview 

  [void]$TV.Nodes.Add($TNRoot) 

  # Add the Controls to the Form 
   
  $form.Controls.Add($TV) 
  $form.Controls.Add($btnSelect )  
  $form.Controls.Add($btnCancel ) 

  # Set the Select Button as the Default 
  
  $form.AcceptButton =  $btnSelect 
      
  $Form.Add_Shown({$form.Activate()})    
  [void]$form.showdialog()  

  # Return selected DirectoryEntry or $false as Cancel Button is Used 
  Return $script:Return 
}

###################################################################### Main Script #################################################################


$menu = "INVENTORY FILES ON COMPUTERS"
$sourceAD = New-Object System.Management.Automation.Host.ChoiceDescription "Inventory files on computers (source &AD)", "Inventory files on computers (source AD)."
$sourceFILE = New-Object System.Management.Automation.Host.ChoiceDescription "Inventory files on computers (source &TEXT file)", "Inventory files on computers (source TEXT file)."
$localos = New-Object System.Management.Automation.Host.ChoiceDescription "Inventory files on &LOCAL computer", "Inventory files on LOCAL computer."
$quit = New-Object System.Management.Automation.Host.ChoiceDescription "&Quit", "Exit the script."
$optionsmenu = [System.Management.Automation.Host.ChoiceDescription[]]($sourceAD,
    $sourceFILE, 
    $localos, 
    $quit)
do { # Menu
    $promptMenu = $host.ui.PromptForChoice($null, $menu, $optionsmenu, 3)
    if ($promptMenu -eq 3) {
        # ending script
        Write-Host "Application closed." -ForegroundColor Yellow -BackgroundColor Black
        exit}


    
    switch ($promptMenu) {
            0   {# INVENTORY - SOURCE AD
            Write-Host


                # Get Domain(s) Name(s)
    $FullDomainName = getfulldomainname

    # Get Domain Suffix
    $DomainSuffix = $FullDomainName.split(".")[$FullDomainName.split(".").count-1]

    # Get Domain Name(s)
    if ($FullDomainName.count -gt 2) {
        $DomainArray = $FullDomainName[0..($FullDomainName.count-2)]
        $Domain = $DomainArray -join (".")
        Write-Host "Script found more domains."
        }
    $Domain = $FullDomainName.split(".")[0]

                           ##### FILE FILTER CONFIG
                $menufilefilter = "Choose Inventory File Filter"
                $exe = New-Object System.Management.Automation.Host.ChoiceDescription "&EXE Files", "EXE Files."
                $xls = New-Object System.Management.Automation.Host.ChoiceDescription "&XLS and XLSX Files", "XLS and XLSX Files."
                $dll = New-Object System.Management.Automation.Host.ChoiceDescription "&DLL Files", "DLL Files."
                $custom = New-Object System.Management.Automation.Host.ChoiceDescription "&Custom Files", "Custom Files."
                $quit = New-Object System.Management.Automation.Host.ChoiceDescription "&Quit", "Exit the script."
                $optionsfilefiltermenu = [System.Management.Automation.Host.ChoiceDescription[]]($exe,
                    $xls,
                    $dll, 
                    $custom, 
                    $quit)

                    $promptFileFilterMenu = $host.ui.PromptForChoice($null, $menufilefilter, $optionsfilefiltermenu, 3)
                    switch ($promptFileFilterMenu) {
                        0 {$filefilter = '*.exe'}
                        1 {$filefilter = '*.xls'}
                        2 {$filefilter = '*.dll'}
                        3 {$filefilter = Read-Host 'Enter the pattern for filter. For example *.xlsx or *.xls,*.docx or sys*.ex*'}
                        4 {exit}
                        }
               
               write-verbose "filefilter is $filefilter"
               ####### END FILE FILTER CONFIG



            # Get Company Name
            #$Company = getcompanyname
            # Get ADDC Hostname, test whether is not empty and try connection
            $DomainController = getdcname
            #$DomainController = 'redlabdc1'
            Write-Host
            Write-Host "Testing connection to the specified Domain Controller. Please wait..." -ForegroundColor Yellow
            Clear-Variable ErrDCConnection -ErrorAction SilentlyContinue
            Invoke-Command -ComputerName $DomainController -ScriptBlock {} -ErrorVariable ErrDCConnection -ErrorAction SilentlyContinue
            # write-host ("error je " + $ErrDCConnection)
            if ($ErrDCConnection) {
                do {
                    Write-host ("Connection to the Domain Controller $DomainController failed. Error output is:") -BackgroundColor yellow -ForegroundColor red
                    Write-host $errDCConnection -BackgroundColor red -ForegroundColor white
                    $messagedc = "Do you want to connect to the other Domain Controller"
                    $yesdc = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Connect to another DC."
                    $optionsdc = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $quit)
                        do { # Ask for other DC
                        $promptResultdc = $host.ui.PromptForChoice($null, $messagedc, $optionsdc, 0)
                            switch ($promptResultdc)
                            {
                                1   {# QUIT = shutdown the script
                                    exit
                                    }           
                                } 
                            }
                        until ($promptResultdc -eq 0)
                        Clear-Variable ErrDCConnection
                        $DomainController = getdcname
                }
                until ($ErrDCConnection -eq $null)
            } #End if
            Write-Host "Connection test passed." -ForegroundColor Yellow
            Write-Host


            # Get LDAP
            $LDAP = getldapou
            # Create AD Users
            # Connect to Domain Controller
            $devices = invoke-command -computername $DomainController -ArgumentList $Users,$LDAP,$Domain,$DomainSuffix,$Company,$Count -scriptblock {param($InnerUsers,$InnerLDAP,$InnerDomain,$InnerDomainSuffix,$InnerCompany,$InnerCount)
               # Show me where I am
               $connecteddc = hostname
               # counter
               $object = 1
               write-host ("Connected to Domain Controller: " + $connecteddc) -foregroundcolor yellow
               # Import AD Module
               Import-Module ActiveDirectory
               write-host "Active Directory module imported." -foregroundcolor yellow
               # Create AD Users
               write-host "`$InnerLDAP is $innerldap"


               
               $innerdevices = (Get-ADComputer -Filter * -SearchBase "$InnerLDAP").DNSHostName
               return $innerdevices
          
               

               }  # End of Remote Session

               


                do-inventory -devicelist $devices -filter $filefilter

               write-host "Menu step finished. Unloading modules..." -foregroundcolor yellow
               Write-Host
            } #End of switch 0 


            1 {# INVENTORY - SOURCE CSV FILE
            Write-Host
            



                do {$devicelist = Get-OpenFile -initialDirectory $env:USERPROFILE\desktop} until ($devicelist)

                           ##### FILE FILTER CONFIG
                $menufilefilter = "Choose Inventory File Filter"
                $exe = New-Object System.Management.Automation.Host.ChoiceDescription "&EXE Files", "EXE Files."
                $xls = New-Object System.Management.Automation.Host.ChoiceDescription "&XLS and XLSX Files", "XLS and XLSX Files."
                $dll = New-Object System.Management.Automation.Host.ChoiceDescription "&DLL Files", "DLL Files."
                $custom = New-Object System.Management.Automation.Host.ChoiceDescription "&Custom Files", "Custom Files."
                $quit = New-Object System.Management.Automation.Host.ChoiceDescription "&Quit", "Exit the script."
                $optionsfilefiltermenu = [System.Management.Automation.Host.ChoiceDescription[]]($exe,
                    $xls,
                    $dll, 
                    $custom, 
                    $quit)

                    $promptFileFilterMenu = $host.ui.PromptForChoice($null, $menufilefilter, $optionsfilefiltermenu, 3)
                    switch ($promptFileFilterMenu) {
                        0 {write-host 'exe filter';$filefilter = '*.exe'}
                        1 {write-host 'xls filter';$filefilter = '*.xls'}
                        2 {write-host 'dll filter';$filefilter = '*.dll'}
                        3 {write-host 'custom filter';$filefilter = Read-Host 'Enter the pattern for filter. For example *.xlsx or *.xls,*.docx or sys*.ex*'}
                        4 {Write-Host "Application closed." -ForegroundColor Yellow -BackgroundColor Black;exit}
                        }
               
               write-verbose "`$filefilter is $filefilter"
               ####### END FILE FILTER CONFIG

               $devices = Get-Content $devicelist


               do-inventory -devicelist $devices -filter $filefilter

               write-host "Menu step finished. Unloading modules..." -foregroundcolor yellow
               Write-Host
                } # End of switch 1
            
            2 {# LOCAL COMPUTER
Write-Host
           

                           ##### FILE FILTER CONFIG
                $menufilefilter = "Choose Inventory File Filter"
                $exe = New-Object System.Management.Automation.Host.ChoiceDescription "&EXE Files", "EXE Files."
                $xls = New-Object System.Management.Automation.Host.ChoiceDescription "&XLS and XLSX Files", "XLS and XLSX Files."
                $dll = New-Object System.Management.Automation.Host.ChoiceDescription "&DLL Files", "DLL Files."
                $custom = New-Object System.Management.Automation.Host.ChoiceDescription "&Custom Files", "Custom Files."
                $quit = New-Object System.Management.Automation.Host.ChoiceDescription "&Quit", "Exit the script."
                $optionsfilefiltermenu = [System.Management.Automation.Host.ChoiceDescription[]]($exe,
                    $xls,
                    $dll, 
                    $custom, 
                    $quit)

                    $promptFileFilterMenu = $host.ui.PromptForChoice($null, $menufilefilter, $optionsfilefiltermenu, 3)
                    switch ($promptFileFilterMenu) {
                        0 {$filefilter = '*.exe'}
                        1 {$filefilter = '*.xls'}
                        2 {$filefilter = '*.dll'}
                        3 {$filefilter = Read-Host 'Enter the pattern for filter. For example *.xlsx or *.xls,*.docx or sys*.ex*'}
                        4 {Write-Host "Application closed." -ForegroundColor Yellow -BackgroundColor Black;exit}
                        }
               
               write-verbose "`$filefilter is $filefilter"
               ####### END FILE FILTER CONFIG

        


               do-localinventory -filter $filefilter

               write-host "Menu step finished. Unloading modules..." -foregroundcolor yellow
               Write-Host
                } # End of switch 2

        } #End of switching
    } # End of do
until ($promptResultdc -eq 3)

Write-Host "Application closed." -ForegroundColor Yellow -BackgroundColor Black




# future features
# 1. input list of PCs from CSV
# 2. xml file to configure pattern where to find files on targeted devices