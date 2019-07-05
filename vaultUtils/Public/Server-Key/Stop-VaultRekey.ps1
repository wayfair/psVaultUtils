function Stop-VaultRekey {
<#
.Synopsis
    Stops the curent rekey attempt.

.DESCRIPTION
    Stop-VaultRekey will stop the current rekey attempt. 

.EXAMPLE
    PS> Stop-VaultRekey

    This command does not require any parameters or produce any output.

#>
    [CmdletBinding()]
    param()

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
    }

    process {
        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/rekey/init"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Delete'
        }

        try {
            Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }
    }

    end {

    }
}

Set-Alias -Name 'Cancel-VaultRekey' -Value 'Stop-VaultRekey'