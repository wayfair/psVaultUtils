function Clear-VaultSessionVariable {
<#
.Synopsis
    Clears the contents of VAULT_ variables.

.DESCRIPTION
    Clear-VaultSessionVariable clears the contents of all VAULT_ variables. 
    Accepts pipeline input via Get-VaultSessionVariable or a variable containing vault-related key-value pairs. 

.EXAMPLE
    PS> Clear-VaultSessionVariable

    PS> Get-VaultSessionVariable

    Name                           Value
    ----                           -----
    VAULT_ADDR
    VAULT_ADDR_STANDBY
    VAULT_CRED
    VAULT_LOGIN_METHOD
    VAULT_NODES
    VAULT_TOKEN

.EXAMPLE 
    PS> Get-VaultSessionVariable | Where-Object Name -eq "VAULT_ADDR" | Clear-VaultSessionVariable

    This command does not produce any output.
#>
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true
        )]
        $Variables
    )

    begin {

    }

    process {
        if ($Variables) {
            $Variables | Clear-Variable -Scope 'Global'
        }
        else {
            Get-Variable | Where-Object Name -match "VAULT_" | Clear-Variable -Scope 'Global'
        }
    }

    end {

    }
}
    