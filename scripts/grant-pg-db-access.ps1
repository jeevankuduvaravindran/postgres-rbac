Set-StrictMode -Version 3.0

param (
    [Parameter(Mandatory)]
    [string]$PostgresHost,
    [Parameter(Mandatory)]
    [string]$PostgresDatabase,
    [Parameter(Mandatory)]
    [string]$ServiceMIName,
    [Parameter(Mandatory)]
    [string]$PlatformMIName,
    [Parameter(Mandatory)]
    [string]$PlatformMIClientId,
    [Parameter(Mandatory)]
    [string]$PlatformMIFederatedTokenFile,
    [Parameter(Mandatory)]
    [string]$PlatformMITenantId,
    [Parameter(Mandatory)]
    [string]$PlatformMISubscriptionId
)

[string]$functionName = $MyInvocation.MyCommand
[DateTime]$startTime = [DateTime]::UtcNow
[int]$exitCode = -1
[bool]$setHostExitCode = (Test-Path -Path ENV:TF_BUILD) -and ($ENV:TF_BUILD -eq "true")
[bool]$enableDebug = (Test-Path -Path ENV:SYSTEM_DEBUG) -and ($ENV:SYSTEM_DEBUG -eq "true")

Set-Variable -Name ErrorActionPreference -Value Continue -scope global
Set-Variable -Name VerbosePreference -Value Continue -Scope global

if ($enableDebug) {
    Set-Variable -Name DebugPreference -Value Continue -Scope global
    Set-Variable -Name InformationPreference -Value Continue -Scope global
}

Write-Host "${functionName} started at $($startTime.ToString('u'))"
Write-Debug "${functionName}:PostgresHost:$PostgresHost"
Write-Debug "${functionName}:PostgresDatabase:$PostgresDatabase"
Write-Debug "${functionName}:ServiceMIName:$ServiceMIName"
Write-Debug "${functionName}:PlatformMIClientId=$PlatformMIClientId"
Write-Debug "${functionName}:PlatformMIFederatedTokenFile=$PlatformMIFederatedTokenFile"
Write-Debug "${functionName}:PlatformMITenantId=$PlatformMITenantId"
Write-Debug "${functionName}:PlatformMISubscriptionId=$PlatformMISubscriptionId"

[System.IO.DirectoryInfo]$scriptDir = $PSCommandPath | Split-Path -Parent
Write-Debug "${functionName}:scriptDir.FullName:$($scriptDir.FullName)"

try {
    [System.IO.DirectoryInfo]$moduleDir = Join-Path -Path $scriptDir.FullName -ChildPath "modules/psql"
    Write-Debug "${functionName}:moduleDir.FullName:$($moduleDir.FullName)"

    Import-Module $moduleDir.FullName -Force
    
    [string]$connectAzOutput = Connect-AzAccountForPSQL -PlatformMIClientId $PlatformMIClientId -PlatformMIFederatedTokenFile $PlatformMIFederatedTokenFile -PlatformMITenantId $PlatformMITenantId -PlatformMISubscriptionId $PlatformMISubscriptionId
    Write-Debug "${functionName}:connectAzOutput:$connectAzOutput"

    [string]$getAccessTokenOutput = Get-AccessTokenForPSQL
    Write-Debug "${functionName}:getAccessTokenOutput:$getAccessTokenOutput"

    [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new()
    
    [void]$builder.Append("GRANT CREATE, USAGE ON SCHEMA public TO `"$ServiceMIName`";")
    [void]$builder.Append("GRANT CREATE, SELECT, UPDATE, INSERT, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public TO`"$ServiceMIName`";")
    [void]$builder.Append("GRANT SELECT, UPDATE, USAGE ON ALL SEQUENCES IN SCHEMA public TO `"$ServiceMIName`";")
    [void]$builder.Append("GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO `"$ServiceMIName`";")
    [void]$builder.Append("GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO `"$ServiceMIName`";")
    
    [string]$command = $builder.ToString()
    Write-Debug "${functionName}:command=$command"
    
    [System.IO.FileInfo]$tempFile = [System.IO.Path]::GetTempFileName()
    [string]$content = Set-Content -Path $tempFile.FullName -Value $command -PassThru -Force
    Write-Debug "${functionName}:$($tempFile.FullName)=$content"

    [string]$output = Invoke-PSQLScript -PostgresHost $PostgresHost -PostgresUsername $PlatformMIName -PostgresDatabase $PostgresDatabase -Path $tempFile.FullName
    Write-Debug "${functionName}:output=$output"

    # Successful exit
    $exitCode = 0
} 
catch {
    $exitCode = -2
    Write-Error $_.Exception.ToString()
    throw $_.Exception
}
finally {
    Remove-Item -Path $tempFile.FullName -Force -ErrorAction SilentlyContinue

    [DateTime]$endTime = [DateTime]::UtcNow
    [Timespan]$duration = $endTime.Subtract($startTime)

    Write-Host "${functionName} finished at $($endTime.ToString('u')) (duration $($duration -f 'g')) with exit code $exitCode"

    if ($setHostExitCode) {
        Write-Debug "${functionName}:Setting host exit code"
        $host.SetShouldExit($exitCode)
    }
    exit $exitCode
}