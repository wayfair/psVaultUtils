function Show-VaultKVSecret {
<#
.Synopsis
    Retrieves a list of key names at a specified Vault secrets path.

.DESCRIPTION
    Show-VaultKVSecret is capable of retrieving a list of key names given a specified vault secrets path.

    Folders are suffixed with "/".
    The input must be a folder; LIST on a file will not return a value.

    Note that no policy-based filtering is performed on keys; do not encode sensitive information in key names. 
    The values themselves are not accessible via this command.

.EXAMPLE
    PS> Show-VaultKVSecret -Engine dsc -SecretsPath SQLAG -OutputType PSObject -JustData | Select-Object -ExpandProperty keys

    conf_ag/
    hp_ag/
    mbam_ag/
    pwst_ag/
    rdw_ag/

.EXAMPLE
    PS> Show-VaultKVSecret -Engine dsc -SecretsPath SQLAG/conf_ag -OutputType PSObject

    request_id     : 19887baa-35ff-5722-ed7c-4f08a4c638d3
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{keys=System.Object[]}
    wrap_info      :
    warnings       :
    auth           :

#>
    [CmdletBinding()]
    param(
        #Specifies a KV engine to retrieve secret keys from.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [String] $Engine,

        #Specifies the secrets path to retrieve secret keys from.
        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [String] $SecretsPath,

        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 2
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the data should be displayed in the console.
        [Parameter(
            Position = 3
        )]
        [Switch] $JustData
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        #This API Endpoint requires the use of the LIST method; Invoke-RestMethod does not natively support the LIST method.
        #Custom REST Methods are introduced in the PowerShell Core version of Invoke-RestMethod. 
        #Adding list = true to the query parameters (body) allows us to work around this limitation.
        $body = @{ list = 'true' }

        $irmParams = @{
            Uri    = "$uri/v1/$Engine/metadata/$SecretsPath"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Get'
            Body   = $body
        }

        try {
            $result = Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }

        $formatParams = @{
            InputObject = $result
            DataType    = 'secret_metadata'
            JustData    = $JustData.IsPresent
            OutputType  = $OutputType
        }

        Format-VaultOutput @formatParams
    }

    end {

    }
}

Set-Alias -Name 'List-VaultKVSecret' -Value 'Show-VaultKVSecret'