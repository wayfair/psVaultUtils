function Protect-Vault {
<#
.Synopsis
    Seals the active vault node.

.DESCRIPTION
    Protect-Vault seals the active Vault node in the cluster. 

    Because only the active node can be sealed via the API, 
    the command has no parameters (aside from common parameters)

.EXAMPLE
    PS> Protect-Vault

    Sealed Active Vault Node: https://DEVBO1CHVAULT02.devcorp.wayfair.com:443

    The only output this command produces is affirmation that the active node was sealed. 
#>
    [CmdletBinding()]
    param()

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $(Get-VaultStatus).cluster_leader

        $irmParams = @{
            Uri    = "$uri/v1/sys/seal"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Put'
        }

        try {
            Invoke-RestMethod @irmParams
            Write-Host "Sealed Active Vault Node: $uri"
        }
        catch {
            throw
        }
    }

    end {

    }
}

Set-Alias -Name 'Seal-Vault' -Value 'Protect-Vault'