function Stop-VaultRootTokenGeneration {
<#
.Synopsis
    Cancels any in-progress root token generation attempts. 

.DESCRIPTION
    Stop-VaultRootTokenGeneration cancels any in-progress root token generation attempts. 
    This clears any progress made. This must be called to change the OTP or PGP key being used.

.EXAMPLE
    PS> Stop-VaultRootTokenGeneration

    This command does not require any parameters and does not produce any outout.

#>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High' 
    )]
    param()

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/generate-root/attempt"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Delete'
        }

        if ($PSCmdlet.ShouldProcess("$($global:VAULT_ADDR.Replace('https://',''))",'Stop root token generation')) {
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

Set-Alias -Name 'Cancel-VaultRootTokenGeneration' -Value 'Stop-VaultRootTokenGeneration'