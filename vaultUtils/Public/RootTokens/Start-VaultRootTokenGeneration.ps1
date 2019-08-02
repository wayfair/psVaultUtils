function Start-VaultRootTokenGeneration {
<#
.Synopsis
    Initializes a new root token generation attempt. Only a single root generation attempt can take place at a time.

.DESCRIPTION
    Start-VaultRootTokenGeneration initializes a new root token generation attempt. 
    Only a single root token generation attempt can take place at a time.

.EXAMPLE
    PS> Start-VaultRootTokenGeneration

    nonce              : 01a0a634-76b6-f6bc-a66d-49f2fbda027a
    started            : True
    progress           : 0
    required           : 2
    complete           : False
    encoded_token      :
    encoded_root_token :
    pgp_fingerprint    :
    otp                : 0fdH30ODKa5OoeDK9XrVrUzBRR
    otp_length         : 26

#>
    [CmdletBinding()]
    param(
        #Specifies a Base64-encoded PGP public key. 
        #The raw bytes of the token will be encrypted with this value before being returned to the final unseal key provider.
        [Parameter(
            Position = 0
        )]
        [ValidateScript({ $_ -match "^[a-zA-Z0-9\+/]*={0,2}$" })]
        [String] $PGPKey,

        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 1
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject'
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        if ($PGPKey) {
            $jsonPayload = @"
{
    "pgp_key": "$PGPKey"
}            
"@
        }

        $irmParams = @{
            Uri    = "$uri/v1/sys/generate-root/attempt"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Put'
        }

        if ($jsonPayload) {
            $irmParams += @{ Body = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress) }
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