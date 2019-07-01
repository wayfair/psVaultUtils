<#
Seals the active instance of Vault.
#>
function Protect-Vault {
    [CmdletBinding()]
    param()

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $(Get-VaultStatus).ClusterLeader

        $irmParams = @{
            Uri    = "$uri/v1/sys/seal"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Put'
        }

        try {
            Invoke-RestMethod @irmParams
            Write-Verbose "Sealed Active Vault Node: $uri"
        }
        catch {
            throw
        }
    }

    end {

    }
}

Set-Alias -Name 'Seal-Vault' -Value 'Protect-Vault'