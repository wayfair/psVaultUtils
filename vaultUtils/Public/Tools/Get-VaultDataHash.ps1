function Get-VaultDataHash {
<#
.Synopsis
    Generates a cryptographic hash, given a specified Base64-encoded string.

.DESCRIPTION
    Get-VaultDataHash generates a cryptographic SHA2 hash, given a specified Base64-encoded string.

.EXAMPLE
    PS> Get-VaultDataHash -Algorithm Sha2-256 -InputObject 'hKuzUdAy1fYk/Vlk68KhsQ==' -Format Hex -JustData

    sum
    ---
    e30321d7e389dda2e36f05d34d34cafcfdc468e3ed8b70c8087ce76c9aae58e8

.EXAMPLE 
    PS> Get-VaultDataHash -Algorithm Sha2-512 -InputObject hKuzUdAy1fYk/Vlk68KhsQ== -Format Base64

    request_id     : b7610f79-fa13-8571-dbf7-c833e50f1485
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{sum=ieqWH1rxCxnPIRATxEu3wyshjZK4aeHmK4ThPe+SzPMrlvvRJhVj4TDubn/++bHN7SK1rb3K+bNKhXVKNcZ1WQ==}
    wrap_info      :
    warnings       :
    auth           :
#>
    [CmdletBinding()]
    param(
        #Specifies a SHA2 Algorithm (Sha2-224, Sha2-256, Sha2-384, Sha2-512) to use to generate a cryptographic hash.
        [ValidateSet('Sha2-224','Sha2-256','Sha2-384','Sha2-512')]
        [String]$Algorithm,

        #Specifies a Base64 encoded string to generate a hash for.
        [ValidateScript({ $_ -match "^[a-zA-Z0-9\+/]*={0,2}$" })]
        [String] $InputObject,

        #Specifies the output of the cryptographic hash, in either Base64 or Hex.
        [ValidateSet('Base64','Hex')]
        [String] $Format = 'Base64',

        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the data should be displayed in the console.
        [Switch] $JustData
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
    }

    process {
        $jsonPayload = @"
{
    "input": "$InputObject",
    "format": "$($Format.ToLower())"
}
"@

        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/tools/hash/$($Algorithm.ToLower())"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Post'
            Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
        }

        try {
            $result = Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }

        switch ($OutputType) {
            'Json' {
                if ($JustData) {
                    $result.data | Select-Object 'sum' | ConvertTo-Json
                }
                else {
                    $result | ConvertTo-Json
                }
            }

            'PSObject' {
                if ($JustData) {
                    $result.data
                }
                else {
                   $result
                }
            }
        }
#>
    }

    end {

    }
}