function Get-VaultCubbyholeSecret {
<#
.Synopsis
    Gets secret data from the cubbyhole.

.DESCRIPTION
    Get-VaultCubbyholeSecret retrieves secrets from the cubbyhole.

.EXAMPLE
    PS> Get-VaultCubbyholeSecret -SecretsPath new/path/foo -OutputType Json
    {
        "request_id":  "d09eca2c-98a8-9c8c-3d81-b6067c76b064",
        "lease_id":  "",
        "renewable":  false,
        "lease_duration":  0,
        "data":  {
                    "foo":  "bar"
                },
        "wrap_info":  null,
        "warnings":  null,
        "auth":  null
    }

.EXAMPLE
    PS> Get-VaultCubbyholeSecret -SecretsPath new/path/foo -OutputType PSObject -JustData

    foo
    ---
    bar

#>
    [CmdletBinding()]
    param(
        #Specifies the secrets path to retrieve secrets from.
        [Parameter(
            Position = 0
        )]
        [String] $SecretsPath,

        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 1
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the data should be displayed in the console.
        [Parameter(
            Position = 2
        )]
        [Switch] $JustData
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/cubbyhole/$SecretsPath"
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