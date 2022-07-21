$users = Get-QADUser -SearchRoot "OU=Regular Users,OU=Users,OU=Users and Groups,DC=cyber-rangers,DC=lab" -ip SamAccountName, ThumbnailPhoto

Foreach ($user in $users) {
$user.DirectoryEntry.thumbnailPhoto | Set-Content ("c:\ADexport\Photos\"+$User.samaccountname+".jpg") -Encoding byte
}