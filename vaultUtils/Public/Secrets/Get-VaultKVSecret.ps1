function Get-VaultKVSecret {
    [CmdletBinding()]
    param(
        [String] $Engine,

        [String] $SecretsPath,

        [Switch] $MetaData,

        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject',

        [Switch] $JustData
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
    }

    process {
        $uri = $global:VAULT_ADDR

        if ($MetaData) {
            $infoType = 'metadata'
        }
        else {
            $infoType = 'data'
        }

        $irmParams = @{
            Uri    = "$uri/v1/$Engine/$infoType/$SecretsPath"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Get'
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