function Get-VaultRekeyProgress {
<#
.Synopsis
    Gets the configuration and progress of the current rekey attempt.

.DESCRIPTION
    Get-VaultRekeyProgress gets the configuration and current progress of the current rekey attempt.

.EXAMPLE
    PS> Get-VaultRekeyProgress

    nonce                 :
    started               : False
    t                     : 0
    n                     : 0
    progress              : 0
    required              : 3
    pgp_fingerprints      :
    backup                : False
    verification_required : False

    This example demonstrates the function, and the fact that a rekey attempt has not been started.

.EXAMPLE 
    PS> Get-VaultRekeyProgress

    nonce                 : c5cb3972-9e52-30eb-e396-32ed62099fb7
    started               : True
    t                     : 5
    n                     : 10
    progress              : 1
    required              : 3
    pgp_fingerprints      :
    backup                : False
    verification_required : True

    This example demonstrates that a rekey attempt is in progress. One out of 3 unseal keys have been provided. 
    Verification of the new unseal keys will be required.

#>
    [CmdletBinding()]
    param(
        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 0
        )]
        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject'
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
    }

    process {
        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/rekey/init"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Get'
        }

        try {
            $result = Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }

        if ($OutputType -eq "Json") {
            $result | ConvertTo-Json
        }
        else {
            $result
        }
    }

    end {

    }
}