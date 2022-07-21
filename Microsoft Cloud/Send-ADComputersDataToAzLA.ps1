
[cmdletbinding()]
param(
    [Parameter(Mandatory=$true)][string]$AzLAWorkspaceID,
    [Parameter(Mandatory=$true)][string]$AzLAPrimaryKey,
    [string]$AzLACustomLogName = 'ADComputers'
    [string[]]$ComputerObjectAttributes = 'ObjectGUID','DistinguishedName','Name','DNSHostName'
)

Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
    #function source: https://docs.microsoft.com/cs-cz/azure/azure-monitor/platform/data-collector-api
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
    return $authorization
}

Function Post-LogAnalyticsData ($customerId, $sharedKey, $POSTBody, $logType, $TimeStampField = "") {
    #function source: https://docs.microsoft.com/cs-cz/azure/azure-monitor/platform/data-collector-api
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $POSTBody.Length
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization"        = $signature;
        "Log-Type"             = $logType;
        "x-ms-date"            = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $POSTBody -UseBasicParsing
    return $response.StatusCode

}


function Send-DataToAzureLA {
    [cmdletbinding()]
    param (
        [string]$LogName,
        $Data,
        [string]$WorkspaceID,
        [string]$WorkspaceKey)

    $DataJSON = $Data | ConvertTo-JSON
    $DataJSONBytes = [System.Text.Encoding]::UTF8.GetBytes($DataJSON)
    $postresult = Post-LogAnalyticsData -customerId $WorkspaceID -sharedKey $WorkspaceKey -logType $LogName -PostBody $DataJSONBytes

    return $postresult
}

Get-ADComputer -Filter * -Properties $ComputerObjectAttributes | `
    Select-Object -Property $ComputerObjectAttributes | 
    Select-object -Property * | ForEach-Object {
    Send-DataToAzureLA -Data $_ -LogName $AzLACustomLogName -WorkspaceID $AzLAWorkspaceID -WorkspaceKey $AzLAPrimaryKey
}


<# KQL Query
SecurityEvent
| where EventID == 4662 and AccountType == "User" and Properties startswith "%%7688"
| project TimeGenerated, Account, ObjectGUID=trim_end("}",replace("%{", "", ObjectName ))
| lookup kind=leftouter (
ADComputers_CL
| distinct ObjectGUID_g, DNSHostName_s
| project ObjectGUID = ObjectGUID_g, DNSHostName_s )
on ObjectGUID
| project Account, DNSHostName_s, TimeGenerated
| sort by TimeGenerated desc 
#>