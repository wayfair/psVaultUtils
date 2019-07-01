function Revoke-VaultLeader {
    [CmdletBinding()]
    param()

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $(Get-VaultStatus).ClusterLeader

        $irmParams = @{
            Uri    = "$uri/v1/sys/step-down"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Put'
        }

        try {
            Invoke-RestMethod @irmParams
            Write-Verbose "Initiated Step-Down on Active Node: $uri"
        }
        catch {
            throw
        }
    }

    end {

    }
}

Set-Alias -Name 'Stepdown-VaultLeader' -Value 'Revoke-VaultLeader'