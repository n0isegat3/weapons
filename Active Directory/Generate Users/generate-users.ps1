$total = 100

$domainname = "cyber-rangers.lab"
$userpath = "OU=Generic Users,OU=Lab,DC=cyber-rangers,DC=lab"
$company = 'Cyber Rangers'
$departments = 'Sales','Research','Marketing','IT'
$offices = Import-Csv .\generate-users-offices.csv -Delimiter ","
$organization = 'Cyber Rangers'
$titles = 'Manager','Consultant','Lead'
$userpassword = 'P@ssw0rd'
$firstnames = get-content .\generate-users-firstnames.csv
$lastnames = get-content .\generate-users-lastnames.csv

for ($userIndex=0; $userIndex -lt $total; $userIndex++)
 {
  $userID = "{0:0000}" -f ($userIndex + 1)
	$userfirstname = $(Get-Random $firstnames)
	$userlastname = $(Get-Random $lastnames)
	$userdisplayname = "$userfirstname $userlastname"
	$username = "$userfirstname`.$userlastname"
	$office = Get-Random $offices
	
  Write-Host "Creating user" ($userIndex + 1) "of" $total ":" $userName



  New-ADUser `
   -AccountPassword (ConvertTo-SecureString $userpassword -AsPlainText -Force) `
   -City $office.city `
   -Company $company `
   -Country $office.country `
   -Department $(Get-Random $departments) `
   -Description ("Cyber Rangers Lab User")`
   -DisplayName $userdisplayname `
   -Division "" `
   -EmailAddress "$userName@$domainname" `
    -EmployeeNumber "$userID" `
   -EmployeeID "ISED$userID" `
   -Enabled $true `
   -Fax "703-555-$userID" `
   -GivenName $userfirstname `
   -HomePhone "703-556-$userID" `
   -Initials "TU$userID" `
   -MobilePhone "703-557-$userID" `
   -Name $userdisplayname `
   -Office $office.office `
   -OfficePhone "703-558-$userID" `
   -Organization $organization `
   -Path $userpath `
   -POBox "PO Box $userID"`
   -PostalCode "" `
   -SamAccountName $userName `
   -State "" `
   -StreetAddress $office.streetaddress `
   -Surname $userlastname `
   -Title $(Get-Random $titles) `
   -UserPrincipalName "$userName@$domainname" `
   -verbose
 }

 pause