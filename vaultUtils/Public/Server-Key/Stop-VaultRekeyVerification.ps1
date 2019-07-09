function Stop-VaultRekeyVerification {
<#
.Synopsis
    Stops any in-progress rekey verification operation. 

.DESCRIPTION
    Stop-VaultRekeyVerification stops any in-progress rekey verification operation. 
    This clears any progress made and resets the nonce. 
    Unlike Stop-VaultRekey, this command only resets the current verification operation, not the entire rekey atttempt. 
    The return value is the same as Get-VaultRekeyVerificationProgress along with the new nonce.

.EXAMPLE
    PS> Stop-VaultRekeyVerification


    nonce    : 9071baf0-0e15-38b3-a9ec-39ad4b8443dd
    started  : True
    t        : 2
    n        : 3
    progress : 0

    This command does not require any parameters.

#>
    [CmdletBinding()]
    param()

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/rekey/verify"
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

Set-Alias -Name 'Cancel-VaultRekeyVerification' -Value 'Stop-VaultRekeyVerification'