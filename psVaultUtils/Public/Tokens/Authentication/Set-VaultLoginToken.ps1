function Set-VaultLoginToken {
<#
.Synopsis
    Assigns a specified token to VAULT_TOKEN.

.DESCRIPTION
    Assigns a specified vault token to the global variable VAULT_TOKEN.

    A vault token is used to authenticate to Vault. Without a valid token, most API endpoints cannot be interacted with.
    This function is almost always paired with Get-VaultToken; VAULT_TOKEN needs to set in order to utilize most funtions in vaultUtils.

.EXAMPLE
    PS> Set-VaultToken -Token s.J9CnwypEiNa6sPB20lmmxZh2 -Passthru

    Name                           Value
    ----                           -----
    VAULT_TOKEN                    s.J9CnwypEiNa6sPB20lmmxZh2

.EXAMPLE 
    PS> Get-Vaulttoken -JustToken | Set-VaultToken

    This command does not produce any output.
#>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param(
        #Specifies a vault token to assign to VAULT_TOKEN.
        [Parameter(
            ValueFromPipeline = $true,
            Mandatory = $true,
            Position = 0
        )]
        $Token,

        #Specifies that the resulting VAULT_TOKEN variable should be displayed in the console.
        [Parameter(
            Position = 1
        )]
        [Switch] $Passthru
    )

    begin {

    }

    process {
        if ($PSCmdlet.ShouldProcess('$global:VAULT_TOKEN','Assign Vault login token')) {
            $global:VAULT_TOKEN = $Token | Find-VaultToken

            if ($Passthru) {
                Get-Variable -Name 'VAULT_TOKEN'
            }
        }
    }

    end {

    }
}