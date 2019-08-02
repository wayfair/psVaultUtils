function Revoke-VaultLeader {
<#
.Synopsis
    Initiates the step-down procedure for the active vault node.

.DESCRIPTION
    Revoke-VaultLeader triggers the step-down procedure on the active vault node, 
    causing it to become a standby node, and causing another node in the cluster to take on the role of being the active node.

.EXAMPLE
    PS> Revoke-VaultLeader

    Initiated Step-Down on Active Node: https://DEVVAULT02.domain.com:443 
#>
    [CmdletBinding()]
    param()

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $(Get-VaultStatus).cluster_leader

        $irmParams = @{
            Uri    = "$uri/v1/sys/step-down"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Put'
        }

        try {
            Invoke-RestMethod @irmParams
            Write-Host "Initiated Step-Down on Active Node: $uri"
        }
        catch {
            throw
        }
    }

    end {

    }
}

Set-Alias -Name 'Stepdown-VaultLeader' -Value 'Revoke-VaultLeader'