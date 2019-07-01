function Get-VaultRandomBytes {
    [CmdletBinding()]
    param(
        [Int] $Bytes,

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
    "format": "$($Format.ToLower())"
}
"@

        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/tools/random/$Bytes"
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
                    $result.data | Select-Object 'random_bytes' | ConvertTo-Json
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
    }

    end {

    }
}