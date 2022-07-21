[cmdletbinding()]
param(
    [Parameter(Mandatory=$true,HelpMessage='Example: 0deac605-b748-47bc-acca-7cf9afdb368e')][string]$AzLAWorkspaceID,
    [Parameter(Mandatory=$true,HelpMessage='Example: AFe8DBGqcKZNHLZAGxbIxWaDZvCrM5s3jknQ4XR9+j3w1MJijDBD00gsq/oaDZtWQLO45cdoKBsZaE7dAAHKPO==')][string]$AzLAPrimaryKey,
    [Parameter(Mandatory=$true,HelpMessage='Example: HAFNIUMArtefacts')][string]$AzLACustomLogName,
    [Parameter(Mandatory=$true,HelpMessage='Example: D:\inetpub\logs\LogFiles\W3SVC1\')][ValidateScript( {if (-Not ($_ | Test-Path)) {throw "Folder $_ does not exist"}; return $true})][string]$Path_IISLogs1,
    [Parameter(Mandatory=$true,HelpMessage='Example: D:\inetpub\logs\LogFiles\W3SVC2\')][ValidateScript( {if (-Not ($_ | Test-Path)) {throw "Folder $_ does not exist"}; return $true})][string]$Path_IISLogs2,
    [Parameter(Mandatory=$true,HelpMessage='Example: D:\Logs\MessageTracking')][ValidateScript( {if (-Not ($_ | Test-Path)) {throw "Folder $_ does not exist"}; return $true})][string]$Path_ExchangeMessageTracking,
    [Parameter(Mandatory=$true,HelpMessage='Example: C:\Program Files\Microsoft\Exchange Server\V15')][ValidateScript( {if (-Not ($_ | Test-Path)) {throw "Folder $_ does not exist"}; return $true})][string]$ExchangeServerInstallationFolder,
    [string]$TempFolder = $env:TEMP,
    [int]$AzLAPaging = 10000
)

#region FUNCTIONS
function Send-FileLinesToAzLA {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)][string]$AzLAWorkspaceID,
        [Parameter(Mandatory = $true)][string]$AzLAPrimaryKey,
        [Parameter(Mandatory = $true)][string]$AzLACustomLogName,
        [Parameter(Mandatory = $true)][string]$FilePath,
        [int]$Paging = 1000
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

        if ($LineNumber % $Paging -eq 0) {
            Write-Host "$(get-date -Format s) Sending $($PreviousSendLineNumber+1) - $LineNumber lines to AzLA..." -ForegroundColor black -BackgroundColor Yellow
            $result = Send-DataToAzureLA -Data $objects_paged -LogName $AzLACustomLogName -WorkspaceID $AzLAWorkspaceID -WorkspaceKey $AzLAPrimaryKey
            if ($result -ne 200) {
                throw "$(get-date -Format s) Error Sending Data to Azure Log Analytics"
            }
            else {
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
    }
    else {
        Write-Host "$(get-date -Format s) `tSuccessfully completed." -ForegroundColor black -BackgroundColor green
    }

    Write-Host "$(get-date -Format s) Completed." -ForegroundColor white -BackgroundColor blue
}
#endregion FUNCTIONS

$AzLAKeys = @{
    AzLAWorkspaceID   = $AzLAWorkspaceID
    AzLAPrimaryKey    = $AzLAPrimaryKey
    AzLACustomLogName = $AzLACustomLogName
}

[string[]]$ExchangeFoldersToAnalyze = `
('Logging\HttpProxy\Autodiscover',
'Logging\HttpProxy\Eas\',
'Logging\HttpProxy\Ecp\',
'Logging\HttpProxy\Ews\',
'Logging\HttpProxy\Mapi\',
'Logging\HttpProxy\Oab\',
'Logging\HttpProxy\Owa\',
'Logging\HttpProxy\OwaCalendar\',
'Logging\HttpProxy\PowerShell\',
'Logging\HttpProxy\Rest\',
'Logging\HttpProxy\RpcHttp\',
'Logging\ECP\Server')

foreach ($Item in (get-ChildItem -path $Path_IISLogs1 -Recurse | select-object -ExpandProperty FullName)) { Send-FileLinesToAzLA @AzLAKeys -Paging $AzLAPaging -FilePath $Item }
foreach ($Item in (get-ChildItem -path $Path_IISLogs2 -Recurse | select-object -ExpandProperty FullName)) { Send-FileLinesToAzLA @AzLAKeys -Paging $AzLAPaging -FilePath $Item }
foreach ($Item in (get-ChildItem -path $Path_MessageTracking -Recurse | select-object -ExpandProperty FullName)) { Send-FileLinesToAzLA @AzLAKeys -Paging $AzLAPaging -FilePath $Item }
foreach ($Item in (get-ChildItem -path $Path_ECPLogging -Recurse | select-object -ExpandProperty FullName)) { Send-FileLinesToAzLA @AzLAKeys -Paging $AzLAPaging -FilePath $Item }


foreach ($ExchangeFolderToAnalyze in $ExchangeFoldersToAnalyze) {
    foreach ($Item in (get-ChildItem -path (Join-Path $ExchangeServerInstallationFolder $ExchangeFolderToAnalyze) -Recurse -File | select-object -ExpandProperty FullName)) {
        Send-FileLinesToAzLA @AzLAKeys -Paging $AzLAPaging -FilePath $Item
    }
}

Get-ChildItem -path $env:SystemDrive -Recurse | Get-FileHash -Algorithm SHA256 | Export-Csv (Join-Path $TempFolder 'SystemDriveHashes.csv') -Encoding Unicode -Delimiter "|"
Send-FileLinesToAzLA @AzLAKeys -Paging $AzLAPaging -FilePath (Join-Path $TempFolder 'SystemDriveHashes.csv')