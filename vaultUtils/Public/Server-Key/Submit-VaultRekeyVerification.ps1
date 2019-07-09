function Submit-VaultRekeyVerification {
<#
.Synopsis
    

.DESCRIPTION
    

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

        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 1
        )]
        [ValidateSet('Json','PSObject')]
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