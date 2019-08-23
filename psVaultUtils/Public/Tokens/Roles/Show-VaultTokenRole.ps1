function Show-VaultTokenRole {
<#
.Synopsis

.DESCRIPTION

.EXAMPLE
    PS> 

.EXAMPLE 
    PS>
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