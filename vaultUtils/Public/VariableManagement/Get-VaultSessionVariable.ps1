function Get-VaultSessionVariable {
<#
.Synopsis
    Displays the contents of all VAULT_ variables in the console.

.DESCRIPTION
    Get-VaultSessionVariable executes Get-Variable, filtering on variables named "VAULT_".

    If a PSTranscript is running when this command is executed, the transcript is 
    stopped to prevent a scenario where a token is written to disk.

.EXAMPLE
    PS> Get-VaultSessionVariable

    Name                           Value
    ----                           -----
    VAULT_ADDR                     https://active.vault.service.consul.devcorp.wayfair.com
    VAULT_ADDR_STANDBY             https://standby.vault.service.consul.devcorp.wayfair.com
    VAULT_CRED                     System.Management.Automation.PSCredential
    VAULT_LOGIN_METHOD             LDAP
    VAULT_NODES                    {devbo1chvault01.devcorp.wayfair.com, devbo1chvault02.devcorp.wayfair.com}
    VAULT_TOKEN                    s.JAXF5ifMEo5oi6ZFZHvO1wBv

    This command does not require any input.
#>
    [CmdletBinding()]
    param()

    begin {
        Try {
            Stop-Transcript
            Write-Warning "A running Transcript was stopped to prevent writing token information to disk."
        }
        Catch {
            #Transcript was not running.
        }
    }

    process {
        Get-Variable | Where-Object Name -match "VAULT_"
    }

    end {

    }
}
