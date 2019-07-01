function New-VaultWrapping {
    [CmdletBinding()]
    param(
        [Hashtable] $WrapData,

        [Alias('TTL')]
        [ValidateScript({ $_ -match "^\d+$|^\d+[smh]$" })]
        [String] $WrapTTL = "24h",

        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject',

        [Switch] $JustData
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
    }

    process {
        $uri = $global:VAULT_ADDR

        $wrapDataKV = @()
        foreach ($wd in $WrapData.GetEnumerator()) {
            $wrapDataKV += "`"$($wd.Name)`": `"$($wd.Value)`""
        }

        $jsonPayload = @"
{
    $($wrapDataKV -join ", ")
}      
"@

        $irmParams = @{
            Uri    = "$uri/v1/sys/wrapping/wrap"
            Header = @{ 
                "X-Vault-Token"    = $global:VAULT_TOKEN
                "X-Vault-Wrap-TTL" = $WrapTTL
            }
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
                    $result.wrap_info | ConvertTo-Json
                }
                else {
                    $result | ConvertTo-Json
                }
            }

            'PSObject' {
                if ($JustData) {
                    $result.wrap_info
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

Set-Alias -Name 'Wrap-VaultWrapping' -Value 'New-VaultWrapping'