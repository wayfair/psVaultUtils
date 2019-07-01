function Get-VaultDataHash {
    [CmdletBinding()]
    param(
        [ValidateSet('Sha2-224','Sha2-256','Sha2-384','Sha2-512')]
        [String]$Algorithm,

        [ValidateScript({ $_ -match "^[a-zA-Z0-9\+/]*={0,2}$" })]
        [String] $InputObject,

        [ValidateSet('Base64','Hex')]
        [String] $Format = 'Base64',

        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject',

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