function Get-VaultPolicy {
<#
.Synopsis
    Retrieves the policy body of a specified policy from Vault.

.DESCRIPTION
    Get-VaultPolicy retrieves the policy body of a specified policy from Vault. 

.EXAMPLE
    PS> Get-VaultPolicy -PolicyName dsc-secret-consumer

    rules          : # Allow a token to manage DSC KV
                    path "dsc/*" {
                    capabilities = ["create", "read", "update", "delete", "list"]
                    }
    name           : dsc-secret-consumer
    request_id     : 2e5514be-f4a6-65d0-a032-a57169a6770f
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{name=dsc-secret-consumer; rules=# Allow a token to manage DSC KV
                    path "dsc/*" {
                    capabilities = ["create", "read", "update", "delete", "list"]
                    }}
    wrap_info      :
    warnings       :
    auth           :

.EXAMPLE
    PS> Get-VaultPolicy -PolicyName operator -JustData -OutputType Json
    {
        "name":  "operator",
        "rules":  "#Operators can do everything.\npath \"*\" {\n\tcapabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\", \"sudo\"]\n}"
    }  
#>
    [CmdletBinding()]
    param(
        #Specifies the name of a policy to retrieve.
        [Parameter(
            Position = 0
        )]
        [String] $PolicyName,

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
            Uri    = "$uri/v1/sys/policy/$PolicyName"
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