function Get-VaultTokenRole {
<#
.Synopsis
    Retrieves information about a specified token role.

.DESCRIPTION
    Get-VaultTokenRole retrieves information about a token role, given the role name.

.EXAMPLE
    PS> Get-VaultTokenRole -RoleName 'log-rotate' -OutputType Json
    {
        "request_id":  "0b88b863-d4bb-bb5e-6c0f-317d73d86cf7",
        "lease_id":  "",
        "renewable":  false,
        "lease_duration":  0,
        "data":  {
                    "allowed_policies":  [
                                            "log-rotation"
                                        ],
                    "disallowed_policies":  [

                                            ],
                    "explicit_max_ttl":  0,
                    "name":  "log-rotate",
                    "orphan":  false,
                    "path_suffix":  "",
                    "period":  86400,
                    "renewable":  true,
                    "token_type":  "default-service"
                },
        "wrap_info":  null,
        "warnings":  null,
        "auth":  null
    }

#>
    [CmdletBinding()]
    param(
        #Specifies the role whose configuration should be retrieved.
        [Parameter(
            Position = 0
        )]
        [String] $RoleName,

        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 1
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the token roles should be displayed in the console.
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
            Uri    = "$uri/v1/auth/token/roles/$RoleName"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Get'
        }

        try {
            $result = Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }

        $formatParams = @{
            InputObject = $result
            DataType    = 'data'
            JustData    = $JustData.IsPresent
            OutputType  = $OutputType
        }

        Format-VaultOutput @formatParams
    }

    end {

    }
}