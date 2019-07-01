function New-VaultKVSecret {
    [CmdletBinding()]
    param(
        [String] $Engine,

        [String] $SecretsPath,

        [Hashtable] $Secrets,

        [ValidateRange(0,10)]
        [Int] $CheckAndSet,

        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject',

        [Switch] $JustData
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
    }

    process {
        $uri = $global:VAULT_ADDR

        $secretString = @()
        foreach ($s in $Secrets.GetEnumerator()) {
            $secretString += "`"$($s.Name)`": `"$($s.Value)`""
        }

        $jsonPayload = @"
{
    "options": {
        "cas": $CheckAndSet
    },
    "data": {
        $($secretString -join ", ")
    }
}      
"@

        $irmParams = @{
            Uri    = "$uri/v1/$Engine/data/$SecretsPath"
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
                    if ($MetaData) {
                        $result.data | ConvertTo-Json
                    }
                    else {
                        $result.data.data | ConvertTo-Json
                    }
                }
                else {
                    $result | ConvertTo-Json
                }
            }

            'PSObject' {
                if ($JustData) {
                    if ($MetaData) {
                        $result.data
                    }
                    else {
                        $result.data.data
                    }
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