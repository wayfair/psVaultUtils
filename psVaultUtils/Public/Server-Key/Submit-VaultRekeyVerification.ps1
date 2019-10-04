function Submit-VaultRekeyVerification {
<#
.Synopsis
    Provides the verification nonce and (at runtime) a single unseal key to progress the rekey verification of Vault.

.DESCRIPTION
    This endpoint is used to enter a single new key share to progress the rekey verification operation. 
    If the threshold number of new key shares is reached, Vault will complete the rekey by performing the actual rotation of the master key. 
    Otherwise, this command must be called multiple times until that threshold is met. The nonce must be provided with each call.

    When the operation is complete, this will return a response like in the help examples; 
    otherwise the response will be the same as the Get-VaultRekeyVerificationProgress, providing status on the operation itself.

    If verification was requested, successfully completing this flow will immediately put the operation into a verification state, 
    and provide the nonce for the verification operation.

    NOTE: The default output of this command is Json to ensure ALL KEYS get written to the console.

.EXAMPLE
    PS> Submit-VaultRekeyVerification -Nonce eedd2c4f-8420-aeb9-b41f-eaa77e0599b6
    Please provide a single Unseal Key: ********************************************
    {
        "nonce":  "eedd2c4f-8420-aeb9-b41f-eaa77e0599b6",
        "started":  true,
        "t":  2,
        "n":  3,
        "progress":  1
    }

.EXAMPLE 
    PS> Submit-VaultRekeyVerification -Nonce eedd2c4f-8420-aeb9-b41f-eaa77e0599b6
    Please provide a single Unseal Key: ********************************************
    {
        "nonce":  "eedd2c4f-8420-aeb9-b41f-eaa77e0599b6",
        "complete":  true
    }

#>
    [CmdletBinding()]
    param(
        #Specifies the none of the rekey operation.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [String] $Nonce,

        #Specifies how output information should be displayed in the console. Available options are JSON, PSObject or Hashtable.
        [Parameter(
            Position = 1
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'Json'
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $unsealKey = Read-Host -AsSecureString -Prompt 'Please provide a single Unseal Key'

        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($unsealKey)
        $plainUnsealKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

        $jsonPayload = @"
{
    "key": "$plainUnsealKey",
    "nonce": "$nonce"
}
"@

        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/rekey/verify"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Put'
            Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
        }

        try {
            $result = Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }

        $formatParams = @{
            InputObject = $result
            JustData    = $false
            OutputType  = $OutputType
        }

        Format-VaultOutput @formatParams
    }

    end {

    }
}