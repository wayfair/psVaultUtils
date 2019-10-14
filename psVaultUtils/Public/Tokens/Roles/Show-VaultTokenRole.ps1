function Show-VaultTokenRole {
<#
.Synopsis
    Retrieves all available token roles.

.DESCRIPTION
    Show-VaultTokenRole retrieves all available token roles.

    Show-VaultTokenRole will throw a generic error if there are no roles to list. 

.EXAMPLE
    PS> Show-VaultTokenRole -JustData | Select-Object -ExpandProperty keys

    log-rotate
    trusted-jenkins-app
    trusted-dsc-app

    This example demonstrates listing all of the available token roles.

.EXAMPLE
    PS> Show-VaultTokenRole -OutputType json
    {
        "request_id":  "462bf579-0510-92c9-7a72-9a607f05dc3a",
        "lease_id":  "",
        "renewable":  false,
        "lease_duration":  0,
        "data":  {
                    "keys":  [
                                "log-rotate",
                                "trusted-jenkins-app",
                                "trusted-dsc-app"
                            ]
                },
        "wrap_info":  null,
        "warnings":  null,
        "auth":  null
    }

#>
    [CmdletBinding()]
    param(
        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 0
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the token roles should be displayed in the console.
        [Parameter(
            Position = 1
        )]
        [Switch] $JustData
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR
        
        $body = @{ list = 'true' }

        $irmParams = @{
            Uri    = "$uri/v1/auth/token/roles"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Body   = $body
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

Set-Alias -Name 'List-VaultTokenRole' -Value 'Show-VaultTokenRole'