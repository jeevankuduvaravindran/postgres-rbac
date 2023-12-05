[bool]$enableDebug = $ENV:SYSTEM_DEBUG -eq "true"

if ($enableDebug) {
    Set-Variable -Name DebugPreference -Value Continue -Scope global
    Set-Variable -Name InformationPreference -Value Continue -Scope global
}
 
[string]$PlatformMIClientId = $env:AZURE_CLIENT_ID
[string]$PlatformMITenantId = $env:AZURE_TENANT_ID
[string]$PlatformMISubscriptionId = $env:PLATFORM_MI_SUBSCRIPTION_ID 
[string]$PlatformMIFederatedTokenFile = $env:AZURE_FEDERATED_TOKEN_FILE
[string]$SubscriptionName = $env:SUBSCRIPTION_NAME

Write-Host "Running the powershell script with parameters $Params"

Write-Host "Connecting to Azure..."
$null = Connect-AzAccount -ServicePrincipal -ApplicationId $PlatformMIClientId -FederatedToken $(Get-Content $PlatformMIFederatedTokenFile -raw) -Tenant $PlatformMITenantId -Subscription $PlatformMISubscriptionId
$null = Set-AzContext -Subscription $SubscriptionName
Write-Host "Connected to Azure and set context to '$SubscriptionName'"

Write-Host "Acquiring Access Token..."
$accessToken = Get-AzAccessToken -ResourceUrl "https://ossrdbms-aad.database.windows.net"
$ENV:PGPASSWORD = $accessToken.Token
Write-Host $ENV:PGPASSWORD
Write-Host "Access Token Acquired"