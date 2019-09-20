function Remove-VaultCubbyholeSecret {
<#
.Synopsis
    Removes secret data from the cubbyhole.

.DESCRIPTION
    Get-VaultCubbyholeSecret removes secrets from the cubbyhole.

.EXAMPLE
    PS> Remove-VaultCubbyholeSecret -SecretsPath new/path/foo

    This command does not produce any output.

#>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        #Specifies the secrets path to retrieve secrets from.
        [Parameter(
            Position = 0
        )]
        [String] $SecretsPath
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/cubbyhole/$SecretsPath"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Delete'
        }

        if ($PSCmdlet.ShouldProcess("$SecretsPath",'Remove cubbyhole secret')) {
            try {
                Invoke-RestMethod @irmParams
            }
            catch {
                throw
            }
        }
    }

    end {

    }
}