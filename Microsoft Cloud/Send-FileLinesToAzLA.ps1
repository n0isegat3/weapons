
[cmdletbinding()]
param(
    [Parameter(Mandatory = $true)][string]$AzLAWorkspaceID,
    [Parameter(Mandatory = $true)][string]$AzLAPrimaryKey,
    [Parameter(Mandatory = $true)][string]$AzLACustomLogName,
    [Parameter(Mandatory = $true)][string]$FilePath,
    [int]$Paging = 1000
)

<# how to use:
PS> .\Send-FileLinesToAzLA.ps1 -AzLAWorkspaceID '123' `
            -AzLAPrimaryKey 'abc==' `
            -AzLACustomLogName TestSyslogFile0001 `
            -FilePath "C:\Temp\filetest.txt" `
            -Paging 250
            -Verbose
#>

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

Write-Host "$(get-date -Format s) Started" -ForegroundColor white -BackgroundColor blue

$objects_paged = New-Object -TypeName System.Collections.ArrayList

$LineNumber = 1
$PreviousSendLineNumber = 0
[System.IO.File]::ReadLines($FilePath) | ForEach-Object {
    Write-Verbose "Processing line $LineNumber"
    Remove-Variable -Name obj -ErrorAction SilentlyContinue
    Remove-Variable -Name objProps -ErrorAction SilentlyContinue
    if (!$($_ -eq $null -or $_ -eq '')) {
        $objProps = @{
            FileName = $(Get-Item $FilePath | Select-Object -ExpandProperty Name)
            FileLine = $_
        }
        $obj = New-Object -TypeName psobject -ArgumentList $objProps    
        $objects_paged.Add($obj) | Out-Null
    }

    if ($LineNumber%$Paging -eq 0) {
        Write-Host "$(get-date -Format s) Sending $($PreviousSendLineNumber+1) - $LineNumber lines to AzLA..." -ForegroundColor black -BackgroundColor Yellow
        $result = Send-DataToAzureLA -Data $objects_paged -LogName $AzLACustomLogName -WorkspaceID $AzLAWorkspaceID -WorkspaceKey $AzLAPrimaryKey
        if ($result -ne 200) {
            throw "$(get-date -Format s) Error Sending Data to Azure Log Analytics"
        } else {
            Write-Host "$(get-date -Format s) `tSuccessfully completed." -ForegroundColor black -BackgroundColor green
        }
        $objects_paged.Clear()
        $PreviousSendLineNumber = $LineNumber
    }
    $LineNumber++
}

#remaining paged objects
Write-Host "$(get-date -Format s) Sending $($PreviousSendLineNumber+1) - $LineNumber lines to AzLA..." -ForegroundColor black -BackgroundColor Yellow
$result = Send-DataToAzureLA -Data $objects_paged -LogName $AzLACustomLogName -WorkspaceID $AzLAWorkspaceID -WorkspaceKey $AzLAPrimaryKey
if ($result -ne 200) {
    throw "$(get-date -Format s) Error Sending Data to Azure Log Analytics"
} else {
    Write-Host "$(get-date -Format s) `tSuccessfully completed." -ForegroundColor black -BackgroundColor green
}

Write-Host "$(get-date -Format s) Completed." -ForegroundColor white -BackgroundColor blue