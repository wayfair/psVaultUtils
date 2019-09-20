function Get-VaultKVSecret {
<#
.Synopsis
    Retrieves a secret or secret metadata from Vault, given a KV Engine and a secret path.

.DESCRIPTION
    Get-VaultKVSecret is capable of retrieving a secret, series of secrets, or secret metadata from Vault,
    given a KV secret engine and a relative path to the secret(s).

.EXAMPLE
    PS> Get-VaultKVSecret -Engine 'dsc' -SecretsPath 'sql_ag/conf_ag'

    request_id     : 2ae62ac5-9e86-3e8c-def6-b4d1440054ac
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{data=; metadata=}
    wrap_info      :
    warnings       :
    auth           :

    Because no OutputType was specified, the information about the secret is returned in full, as a PSObject. 
    Note that the data (the secret information) is masked by default, and needs to be accessed to be exposed.

.EXAMPLE
    PS> Get-VaultKVSecret -Engine dsc -SecretsPath sql_ag/conf_ag -JustData

    sa_sql_dbe_conf
    ---
    Fo0Bar!

    The same command as the previous example, only this time -JustData was specified.
    Now the KV secret is exposed to the console.

.EXAMPLE
    PS> Get-VaultKVSecret -Engine dsc -SecretsPath sql_ag/conf_ag -OutputType Json -MetaData
    {
        "request_id":  "387889af-9bd1-85d2-ac48-78d4d46979c0",
        "lease_id":  "",
        "renewable":  false,
        "lease_duration":  0,
        "data":  {
                    "cas_required":  false,
                    "created_time":  "2019-06-28T17:53:30.0526007Z",
                    "current_version":  1,
                    "max_versions":  0,
                    "oldest_version":  0,
                    "updated_time":  "2019-06-28T17:53:30.0526007Z",
                    "versions":  {
                                    "1":  "@{created_time=2019-06-28T17:53:30.0526007Z; deletion_time=; destroyed=False}"
                                }
                },
        "wrap_info":  null,
        "warnings":  null,
        "auth":  null
    }

    In this example, the metadata of the secret from engine 'dsc' at path 'sql_ag/conf_ag' is shown in the console.
    The data is returned in the JSON format.
#>
    [CmdletBinding()]
    param(
        #Specifies a KV engine to retrieve secrets from.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [String] $Engine,

        #Specifies the secrets path to retrieve secrets from.
        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [String] $SecretsPath,

        #Specifies that metadata about the secret should be retrieved instead of the actual secret.
        [Parameter(
            Position = 2
        )]
        [Switch] $MetaData,

        #Specifies how output information should be displayed in the console. Available options are JSON, PSObject or Hashtable.
        [Parameter(
            Position = 3
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the data should be displayed in the console.
        [Parameter(
            Position = 4
        )]
        [Switch] $JustData
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
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

        if ($MetaData) {
            $dataType = 'secret_metadata'
        }
        else {
            $dataType = 'secret_data'
        }

        $formatParams = @{
            InputObject = $result
            DataType    = $dataType
            JustData    = $JustData.IsPresent
            OutputType  = $OutputType
        }

        Format-VaultOutput @formatParams
    }

    end {

    }
}