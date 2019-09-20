function Submit-VaultRootTokenGeneration {
<#
.Synopsis
    Provides a single master key share to progress the root generation attempt.

.DESCRIPTION
    Submit-VaultRootTokenGeneration provides a single master key share to progress the root generation attempt.
    If the threshold number of master key shares is reached, vault will complete the root generation and issue a new encoded token.

    Otherwise, this function must be called multiple times until that threshold is met. 
    The attempt nonce must be provided with each function call.

.EXAMPLE
    PS> Submit-VaultRootTokenGeneration -Nonce 848b2510-422a-7dc0-80bf-8413569e7f40
    Please provide a single Unseal Key: ********************************************
    {
        "nonce":  "848b2510-422a-7dc0-80bf-8413569e7f40",
        "started":  true,
        "progress":  1,
        "required":  2,
        "complete":  false,
        "encoded_token":  "",
        "encoded_root_token":  "",
        "pgp_fingerprint":  "",
        "otp":  "",
        "otp_length":  0
    }

.EXAMPLE 
    PS> Submit-VaultRootTokenGeneration -Nonce 848b2510-422a-7dc0-80bf-8413569e7f40
Please provide a single Unseal Key: ********************************************
{
    "nonce":  "848b2510-422a-7dc0-80bf-8413569e7f40",
    "started":  true,
    "progress":  2,
    "required":  2,
    "complete":  true,
    "encoded_token":  "Q1QXGgcoVTAIGzALIQUDKmYLc1wuDBl7DgI",
    "encoded_root_token":  "Q1QXGgcoVTAIGzALIQUDKmYLc1wuDBl7DgI",
    "pgp_fingerprint":  "",
    "otp":  "",
    "otp_length":  0
}

#>
    [CmdletBinding()]
    param(
        #Specifies the nonce of the root token generation operation.
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
            Uri    = "$uri/v1/sys/generate-root/update"
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