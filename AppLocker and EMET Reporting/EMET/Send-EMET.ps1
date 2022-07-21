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
$Events = Get-WinEvent -FilterHashtable @{LogName="Application";StartTime=$DateA;EndTime=$DateB} -ErrorAction Stop
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
    $ProviderName =$event.ProviderName
    if ($ProviderName -eq "EMET"){
    $Message = $event.Message
    if ($Message.Length -gt 1024){
    $Message=$Message.Substring(0,1024)}
    Try{
    $objSID = New-Object System.Security.Principal.SecurityIdentifier($event.UserId.ToString())
    $UserId = $objSID.Translate( [System.Security.Principal.NTAccount]).ToString()
    }
    Catch {
    $UserId="Unknown"}
    
    $TimeCreated = $event.TimeCreated
    $MachineName = $event.MachineName
    $Level = $event.level
    $EventId = $event.Id  
    
    $eventXML = [xml]$Event.ToXml()    

$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "sp_AddRecord_AppLocker_EMET_Part"
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

$pProviderName = new-object System.Data.SqlClient.SqlParameter;
$pProviderName.ParameterName = "@ProviderName";
$pProviderName.Direction = [System.Data.ParameterDirection]'Input';
$pProviderName.DbType = [System.Data.DbType]'String';
$pProviderName.size = 50
$pProviderName.Value = $ProviderName

$pLevelDescription = new-object System.Data.SqlClient.SqlParameter;
$pLevelDescription.ParameterName = "@LevelDescription";
$pLevelDescription.Direction = [System.Data.ParameterDirection]'Input';
$pLevelDescription.DbType = [System.Data.DbType]'Int16';
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
$SqlCmd.Parameters.Add($pProviderName);
$SqlCmd.Parameters.Add($pLevelDescription);
$SqlCmd.Parameters.Add($pEventId);
$SqlCmd.Parameters.Add($perr_Handler);


$what = $SqlCmd.ExecuteScalar();
if ($perr_Handler.Value -eq 0){}
Else
{
$eventXML.save($MyDir + "\ErrEvents\" + $MachineName+"_"+ $B.Year+"_"+ $B.Month+"_"+ $B.day+"_"+ $B.hour+"_"+ $B.Minute +"_"+ $y+"_EXEerr_eventlog.xml")
}
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