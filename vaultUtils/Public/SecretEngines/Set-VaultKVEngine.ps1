function Set-VaultKVEngine {
    [CmdletBinding()]
    param(
        [String] $Engine,

        [Int] $MaxVersions,

        [Alias('CASRequired')]
        [Switch] $CheckAndSetRequired,

        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject',

        [Switch] $JustData
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
    }

    process {
        $uri = $global:VAULT_ADDR

        if ($CheckAndSetRequired) {
            $cas = 'true'
        }
        else {
            $cas = 'false'
        }

        $jsonPayload = @"
{
    "max_versions": $MaxVersions,
    "cas_required": $cas
}      
"@

        $irmParams = @{
            Uri    = "$uri/v1/$Engine/config"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
            Method = 'Post'
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
                    $result.data | ConvertTo-Json
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