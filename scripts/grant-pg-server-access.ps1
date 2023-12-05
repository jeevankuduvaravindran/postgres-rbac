Set-StrictMode -Version 3.0

# param (
#     [Parameter(Mandatory)]
#     [string]$PostgresHost,
#     [Parameter(Mandatory)]
#     [string]$PostgresDatabase,
#     [Parameter(Mandatory)]
#     [string]$ServiceMIName,
#     [Parameter(Mandatory)]
#     [string]$PlatformMIName,
#     [Parameter(Mandatory)]
#     [string]$PlatformMIClientId,
#     [Parameter(Mandatory)]
#     [string]$PlatformMIFederatedTokenFile,
#     [Parameter(Mandatory)]
#     [string]$PlatformMITenantId,
#     [Parameter(Mandatory)]
#     [string]$PlatformMISubscriptionId
# )

$PostgresHost = "sndadpdbsps1401.postgres.database.azure.com"
$PostgresDatabase = "ffc-demo-payment"
$ServiceMIName = "sndadpinfmi1401-ffc-demo-payment-service"
$PlatformMIName = "ADP-Plarform-Test-App"
$PlatformMIClientId = "6b57e845-f3a8-4c0f-821b-8d4e99414f87"
$PlatformMITenantId = "6f504113-6b64-43f2-ade9-242e05780007"
$PlatformMISubscriptionId = "55f3b8c6-6800-41c7-a40d-2adb5e4e1bd1"
$PlatformMIFederatedTokenFile = "test"

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
    
    # [string]$connectAzOutput = Connect-AzAccountForPSQL -PlatformMIClientId $PlatformMIClientId -PlatformMIFederatedTokenFile $PlatformMIFederatedTokenFile -PlatformMITenantId $PlatformMITenantId -PlatformMISubscriptionId $PlatformMISubscriptionId
    # Write-Debug "${functionName}:connectAzOutput:$connectAzOutput"

    $securePwd = ConvertTo-SecureString -String "RTd8Q~sB-ursH36c6B3qWI2-r-papsOuaNaonbmf" -AsPlainText -Force
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $PlatformMIClientId, $securePwd
    Connect-AzAccount -ServicePrincipal -TenantId $PlatformMITenantId -Credential $credential

    [string]$getAccessTokenOutput = Get-AccessTokenForPSQL
    Write-Debug "${functionName}:getAccessTokenOutput:$getAccessTokenOutput"

    [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new()
    [void]$builder.Append(' DO $$ ')
    [void]$builder.Append(' BEGIN ')
    [void]$builder.Append("     IF NOT EXISTS (SELECT 1 FROM pgaadauth_list_principals(false) WHERE rolname='$ServiceMIName') THEN ")
    [void]$builder.Append("         PERFORM pgaadauth_create_principal('$ServiceMIName', false, false); ");
    [void]$builder.Append("         RAISE NOTICE 'MANAGED IDENTITY CREATED';")
    [void]$builder.Append('     ELSE ')
    [void]$builder.Append("         RAISE NOTICE 'MANAGED IDENTITY ALREADY EXISTS';")
    [void]$builder.Append('     END IF; ')
    [void]$builder.Append("     EXECUTE ( 'GRANT CONNECT ON DATABASE `"$PostgresDatabase`" TO `"$ServiceMIName`"' );")
    [void]$builder.Append("     RAISE NOTICE 'GRANTED CONNECT TO DATABASE';")
    [void]$builder.Append(" EXCEPTION ")
    [void]$builder.Append("     WHEN OTHERS THEN  ")
    [void]$builder.Append("         RAISE EXCEPTION 'GRANT CONNECT TO DATABASE FAILED: %', SQLERRM; ")
    [void]$builder.Append(' END $$' )
    [string]$command = $builder.ToString()
    Write-Debug "${functionName}:command=$command"
    
    [System.IO.FileInfo]$tempFile = [System.IO.Path]::GetTempFileName()
    [string]$content = Set-Content -Path $tempFile.FullName -Value $command -PassThru -Force
    Write-Debug "${functionName}:$($tempFile.FullName)=$content"

    [string]$output = Invoke-PSQLScript -PostgresHost $PostgresHost -PostgresUsername $PlatformMIName -PostgresDatabase "postgres" -Path $tempFile.FullName
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