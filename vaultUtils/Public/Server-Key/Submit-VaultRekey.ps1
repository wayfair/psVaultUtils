function Submit-VaultRekey {
<#
.Synopsis
    Provides the nonce and (at runtime) a single unseal key to progress the rekey of Vault.

.DESCRIPTION
    This endpoint is used to enter a single master key share to progress the rekey of the Vault. 
    If the threshold number of master key shares is reached, Vault will complete the rekey. Otherwise, this API must be called multiple times until that threshold is met. 
    The rekey nonce operation must be provided with each call.

    When the operation is complete, this will return a response like the example below; 
    otherwise the response will be the same as the GET method against sys/rekey/init, providing status on the operation itself.

    If verification was requested, successfully completing this flow will immediately put the operation into a verification state, 
    and provide the nonce for the verification operation.

    NOTE: The default output of this command is Json to ensure ALL KEYS get written to the console.

.EXAMPLE
    PS> Submit-VaultRekey -Nonce f235240f-33c0-41db-25e4-a5591d6b035a
    Please provide a single Unseal Key: ********************************************


    nonce                 : f235240f-33c0-41db-25e4-a5591d6b035a
    started               : True
    t                     : 5
    n                     : 10
    progress              : 1
    required              : 3
    pgp_fingerprints      :
    backup                : False
    verification_required : True

.EXAMPLE 
    PS> Submit-VaultRekey -Nonce f235240f-33c0-41db-25e4-a5591d6b035a
    Please provide a single Unseal Key: ********************************************


    nonce                 : f235240f-33c0-41db-25e4-a5591d6b035a
    complete              : True
    keys                  : {4198d6600625c45fc2254130e143c99b1dd96acd47ed2801d39aec26b422fc8183,
                            45d70d56ceea083bcc150287d6d6092b68ad6ae7a94812e87e3a3413be780c5b7d,
                            e3e0dc7265aa6adfbb2767756cba2f5dd185a9d04a73ee284fd942107148961f4c,
                            d5c08adb251dfe6ab9412c19221193bab6ddb666ad2ba13e0825a82de98a422d12...}
    keys_base64           : {QZjWYAYlxF/CJUEw4UPJmx3Zas1H7SgB05rsJrQi/IGD, RdcNVs7qCDvMFQKH1tYJK2itauepSBLofjo0E754DFt9,
                            4+DccmWqat+7J2d1bLovXdGFqdBKc+4oT9lCEHFIlh9M, 1cCK2yUd/mq5QSwZIhGTurbdtmatK6E+CCWoLemKQi0S...}
    pgp_fingerprints      :
    backup                : False
    verification_required : True
    verification_nonce    : d39da677-73e3-d2d2-2747-02df824ad91a

#>
    [CmdletBinding()]
    param(
        #Specifies the nonce of the rekey operation.
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
            Uri    = "$uri/v1/sys/rekey/update"
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