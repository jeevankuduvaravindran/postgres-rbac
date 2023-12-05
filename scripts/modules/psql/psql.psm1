Set-StrictMode -Version 3.0

function Invoke-PSQLScript {
    param(
        [Parameter(Mandatory)]
        [string]$PostgresHost,
        [Parameter(Mandatory)]
        [string]$PostgresUsername,
        [Parameter(Mandatory)]
        [string]$PostgresDatabase,
        [Parameter(Mandatory)]
        [string]$Path,
        [switch]$ReturnExitCode
    )
    
    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:begin:start"
        Write-Debug "${functionName}:begin:PostgresHost=$PostgresHost"
        Write-Debug "${functionName}:begin:PostgresUsername=$PostgresUsername"
        Write-Debug "${functionName}:begin:PostgresDatabase=$PostgresDatabase"
        Write-Debug "${functionName}:begin:end"
    }

    process {
        Write-Debug "${functionName}:process:start"
        Write-Debug "${functionName}:begin:Path=$Path"
        [System.Text.StringBuilder]$builder = [System.Text.StringBuilder]::new('psql -A -q ')
        [void]$builder.Append(" -h " + $PostgresHost)
        [void]$builder.Append(" -U " + $PostgresUsername)
        [void]$builder.Append(" " + $PostgresDatabase)
        [void]$builder.Append(" -f '")
        [void]$builder.Append($Path)
        [void]$builder.Append("'")

        $expression = $builder.ToString()
        Write-Debug "${functionName}:process:expression=$expression"
        Write-Host $expression
        [string]$output = Invoke-Expression -Command $expression
        [int]$exitCode = $LASTEXITCODE
        Write-Debug "${functionName}:process:exitCode=$exitCode"
        Write-Debug "${functionName}:process:output=$output"

        if ($ReturnExitCode) {
            Write-Output $exitCode
        }
        else {
            Write-Output $output
            if ($exitCode -ne 0) {
                throw "Non zero exit code: $exitCode"
            }
        }

        Write-Debug "${functionName}:process:end"
    }

    end {
        Write-Debug "${functionName}:end:start"
        Write-Debug "${functionName}:end:end"
    }
}

function Connect-AzAccountForPSQL {
    param(
        [Parameter(Mandatory)]
        [string]$AsoMIClientId,
        [Parameter(Mandatory)]
        [string]$AsoMIFederatedTokenFile,
        [Parameter(Mandatory)]
        [string]$AsoMITenantId,
        [Parameter(Mandatory)]
        [string]$AsoMISubscriptionId,
        [switch]$ReturnExitCode
    )

    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:begin:start"
        Write-Debug "${functionName}:begin:AsoMIClientId=$AsoMIClientId"
        Write-Debug "${functionName}:begin:AsoMIFederatedTokenFile=$AsoMIFederatedTokenFile"
        Write-Debug "${functionName}:begin:AsoMITenantId=$AsoMITenantId"
        Write-Debug "${functionName}:begin:AsoMISubscriptionId=$AsoMISubscriptionId"
        Write-Debug "${functionName}:begin:end"
    }

    process {
        Write-Debug "${functionName}:process:start"
        Connect-AzAccount -ServicePrincipal -ApplicationId $AsoMIClientId -FederatedToken $(Get-Content $AsoMIFederatedTokenFile -raw) -Tenant $AsoMITenantId -Subscription $AsoMISubscriptionId

        Write-Debug "${functionName}:process:end"
    }

    end {
        Write-Debug "${functionName}:end:start"
        Write-Debug "${functionName}:end:end"
    }
}

function Get-AccessTokenForPSQL {
    param(
        [switch]$ReturnExitCode
    )
    
    begin {
        [string]$functionName = $MyInvocation.MyCommand
        Write-Debug "${functionName}:begin:start"
        Write-Debug "${functionName}:begin:end"
    }

    process {
        Write-Debug "${functionName}:process:start"
        $token = Get-AzAccessToken -ResourceUrl "https://ossrdbms-aad.database.windows.net"
        $ENV:PGPASSWORD = $token.Token

        Write-Debug "${functionName}:process:PGPASSWORD:$ENV:PGPASSWORD"
        Write-Debug "${functionName}:process:end"
    }

    end {
        Write-Debug "${functionName}:end:start"
        Write-Debug "${functionName}:end:end"
    }
}