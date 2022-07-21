$myDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$testPathExist=$myDir + "\ErrEvents"
if( -Not (Test-Path -Path $testPathExist ) )
{
    New-Item -ItemType directory -Path $testPathExist
}

$myPathFile = $MyDir + "\Settings.xml"
if( -Not (Test-Path -Path $myPathFile ) )
{
    exit
}
try {
$myDateAsString = (Get-Date).ToString()
[xml]$ConfigFile = Get-Content "$MyDir\Settings.xml"
$Year=$ConfigFile.Settings.LastRunTimeYear
$Month=$ConfigFile.Settings.LastRunTimeMonth
$Day=$ConfigFile.Settings.LastRunTimeDay
$Hour=$ConfigFile.Settings.LastRunTimeHour
$Minute=$ConfigFile.Settings.LastRunTimeMinute
$DateA = get-date -y $Year -mo $Month -day $Day -Hour $Hour -Minute $Minute -Second 0
$B=get-date
$BYear=$B.Year
$BMonth=$B.Month
$BDay=$B.Day
$BHour=$B.Hour
$BMinute=$B.Minute
$DateB = get-date -y $BYear -mo $BMonth -day $BDay -Hour $BHour -Minute $BMinute -Second 0
}
Catch
{$ErrorMessage = $_.Exception.Message
    write-host $ErrorMessage
    exit}
Finally{}


$error.clear()
$Events = Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-AppLocker/EXE and DLL";StartTime=$DateA;EndTime=$DateB} -ErrorAction Stop
 if ($error.Count -gt 0){
 exit
 }
 $y=1
try{
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server=company-sql\sql; Database=DB_AppLocker_EMET_Logs; Integrated Security=True"
$SqlConnection.Open()
$SqlConnection.State
    }
    Catch{
    $ErrorMessage = $_.Exception.Message
    exit
    }
    Finally
    {
            
ForEach ($Event in $Events) {            
    Try{
    $Message=$Event.Message
    if ($Message.Length -gt 1024){
    $Message=$Message.Substring(0,1024)}}
    Catch {$Message="This event not contains Message specifications"
    }
    $UserId = New-Object System.Security.Principal.SecurityIdentifier($event.UserId.ToString())
    Try{
    $objSID = New-Object System.Security.Principal.SecurityIdentifier($event.UserId.ToString())
    $UserId = $objSID.Translate( [System.Security.Principal.NTAccount]).ToString()
    }
    Catch {
    $UserId="Unknown"}
    try{
    $TimeCreated = $event.TimeCreated
    $MachineName = $event.MachineName
    $Level = $event.level
    $EventId = $event.Id  
    }
    Catch {
    $TimeCreated = $B
    $MachineName = "Unknown"
    $Level = 1
    $EventId = 2  
    }
    $eventXML = [xml]$Event.ToXml()
    
    $PolicyName=$eventXML.Event.UserData.RuleAndFileData.PolicyName
    $RuleId=$eventXML.Event.UserData.RuleAndFileData.RuleId
    $RuleSddl=$eventXML.Event.UserData.RuleAndFileData.RuleSddl
    $FilePath=$eventXML.Event.UserData.RuleAndFileData.FilePath
    $FileHash=$eventXML.Event.UserData.RuleAndFileData.FileHash
    $Fqbn=$eventXML.Event.UserData.RuleAndFileData.Fqbn
    if ($PolicyName.Length -eq 0){
    $PolicyName="This event not contains PolicyName specifications"
    $RuleId="This event not contains RuleId specifications"
    $RuleSddl="This event not contains RuleSddl specifications"
    $FilePath="This event not contains FilePath specifications"
    $FileHash="This event not contains FileHash specifications"
    $Fqbn="This event not contains Fqbn specifications"
}
    $error.clear()
    
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "sp_AddRecord_AppLocker_EXEDLL_Part"
$SqlCmd.CommandType = [System.Data.Commandtype]::StoredProcedure
$SqlCmd.Connection = $SqlConnection
$a = Get-Date
$pTimeCreated = new-object System.Data.SqlClient.SqlParameter;
$pTimeCreated.ParameterName = "@TimeCreated";
$pTimeCreated.Direction = [System.Data.ParameterDirection]'Input';
$pTimeCreated.DbType = [System.Data.DbType]'Datetime';
$pTimeCreated.size = 8
$pTimeCreated.Value = $TimeCreated

$pMachineName = new-object System.Data.SqlClient.SqlParameter;
$pMachineName.ParameterName = "@MachineName";
$pMachineName.Direction = [System.Data.ParameterDirection]'Input';
$pMachineName.DbType = [System.Data.DbType]'String';
$pMachineName.size = 50
$pMachineName.Value = $MachineName

$pUserId = new-object System.Data.SqlClient.SqlParameter;
$pUserId.ParameterName = "@UserId";
$pUserId.Direction = [System.Data.ParameterDirection]'Input';
$pUserId.DbType = [System.Data.DbType]'String';
$pUserId.Size = 100
$pUserId.Value = $UserId

$pMessage = new-object System.Data.SqlClient.SqlParameter;
$pMessage.ParameterName = "@Message";
$pMessage.Direction = [System.Data.ParameterDirection]'Input';
$pMessage.DbType = [System.Data.DbType]'String';
$pMessage.size = 1024
$pMessage.Value = $Message

$pPolicyName = new-object System.Data.SqlClient.SqlParameter;
$pPolicyName.ParameterName = "@PolicyName";
$pPolicyName.Direction = [System.Data.ParameterDirection]'Input';
$pPolicyName.DbType = [System.Data.DbType]'String';
$pPolicyName.size = 50
$pPolicyName.Value = $PolicyName

$pRuleId = new-object System.Data.SqlClient.SqlParameter;
$pRuleId.ParameterName = "@RuleId";
$pRuleId.Direction = [System.Data.ParameterDirection]'Input';
$pRuleId.DbType = [System.Data.DbType]'String';
$pRuleId.size = 50
$pRuleId.Value = $RuleId

$pRuleSddl = new-object System.Data.SqlClient.SqlParameter;
$pRuleSddl.ParameterName = "@RuleSddl";
$pRuleSddl.Direction = [System.Data.ParameterDirection]'Input';
$pRuleSddl.DbType = [System.Data.DbType]'String';
$pRuleSddl.size = 50
$pRuleSddl.Value = $RuleSddl

$pFilePath = new-object System.Data.SqlClient.SqlParameter;
$pFilePath.ParameterName = "@FilePath";
$pFilePath.Direction = [System.Data.ParameterDirection]'Input';
$pFilePath.DbType = [System.Data.DbType]'String';
$pFilePath.size = 1024
$pFilePath.Value = $FilePath

$pFileHash = new-object System.Data.SqlClient.SqlParameter;
$pFileHash.ParameterName = "@FileHash";
$pFileHash.Direction = [System.Data.ParameterDirection]'Input';
$pFileHash.DbType = [System.Data.DbType]'String';
$pFileHash.size = 1024
$pFileHash.Value = $FileHash

$pFqbn = new-object System.Data.SqlClient.SqlParameter;
$pFqbn.ParameterName = "@Fqbn";
$pFqbn.Direction = [System.Data.ParameterDirection]'Input';
$pFqbn.DbType = [System.Data.DbType]'String';
$pFqbn.size = 1024
$pFqbn.Value = $Fqbn

$pLevelDescription = new-object System.Data.SqlClient.SqlParameter;
$pLevelDescription.ParameterName = "@LevelDescription";
$pLevelDescription.Direction = [System.Data.ParameterDirection]'Input';
$pLevelDescription.DbType = [System.Data.DbType]'String';
$pLevelDescription.size = 50
$pLevelDescription.Value = $Level

$pEventId = new-object System.Data.SqlClient.SqlParameter;
$pEventId.ParameterName = "@EventId";
$pEventId.Direction = [System.Data.ParameterDirection]'Input';
$pEventId.DbType = [System.Data.DbType]'Int16';
$pEventId.size = 16
$pEventId.Value = $EventId

$perr_Handler = new-object System.Data.SqlClient.SqlParameter;
$perr_Handler.ParameterName = "@err_Handler";
$perr_Handler.Direction = [System.Data.ParameterDirection]'Output';
$perr_Handler.DbType = [System.Data.DbType]'Int16';
$perr_Handler.size = 16
$perr_Handler.Value = 0


$SqlCmd.Parameters.Add($pTimeCreated);
$SqlCmd.Parameters.Add($pMachineName);
$SqlCmd.Parameters.Add($pUserId);
$SqlCmd.Parameters.Add($pMessage);
$SqlCmd.Parameters.Add($pPolicyname);
$SqlCmd.Parameters.Add($pRuleId);
$SqlCmd.Parameters.Add($pRulesddl);
$SqlCmd.Parameters.Add($pFilePath);
$SqlCmd.Parameters.Add($pFileHash);
$SqlCmd.Parameters.Add($pFqbn);
$SqlCmd.Parameters.Add($pLevelDescription);
$SqlCmd.Parameters.Add($pEventId);
$SqlCmd.Parameters.Add($perr_Handler);


$what = $SqlCmd.ExecuteScalar();
if ($perr_Handler.Value -eq 0){}
Else
{
$eventXML.save($MyDir + "\ErrEvents\" + $MachineName+"_"+ $B.Year+"_"+ $B.Month+"_"+ $B.day+"_"+ $B.hour+"_"+ $B.Minute +"_"+ $y+"_EXEerr_eventlog.xml")
}  
    $y++
}
$ConfigFile.Settings.LastRunTime = ($myDateAsString).ToString()
$ConfigFile.Settings.LastRunTimeYear=($BYear).ToString()
$ConfigFile.Settings.LastRunTimeMonth=($BMonth).ToString()
$ConfigFile.Settings.LastRunTimeDay=($BDay).ToString()
$ConfigFile.Settings.LastRunTimeHour=($BHour).ToString()
$ConfigFile.Settings.LastRunTimeMinute=($BMinute).ToString()
$ConfigFile.Save($myPathFile)
    }    