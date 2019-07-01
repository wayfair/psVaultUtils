function Get-VaultKVEngine {
<#
.Synopsis
    Returns information about a KV Engine.

.DESCRIPTION
    Get-VaultKVEngine returns information about a KV Engine, which includes the 
    number of max versions a given secret can contain, and whether or not CheckAndSet (CAS) is required.

.EXAMPLE
    PS> Get-VaultKVEngine -Engine dsc

    request_id     : ab2b05b9-0468-6380-f0c2-9278c50d55d3
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{cas_required=False; max_versions=0}
    wrap_info      :
    warnings       :
    auth           :

.EXAMPLE
    PS> Get-VaultKVEngine -Engine dsc -OutputType Json -JustData
    
    {
        "cas_required":  false,
        "max_versions":  0
    }
#>
    [CmdletBinding()]
    param(
        #Specifies a KV Engine to return information about.
        [String] $Engine,

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
        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/$Engine/config"
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