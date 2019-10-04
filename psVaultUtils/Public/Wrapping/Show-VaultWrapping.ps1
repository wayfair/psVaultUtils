function Show-VaultWrapping {
<#
.Synopsis
    Shows information about wrapped data, given a specified token.

.DESCRIPTION
    Show-VaultWrapping shows information about wrapped data, given a specified token.

    Viewing the information of a wrapped data is not the same as viewing the data itself, 
    and subsequently does not expire the data if wrapping information has been retrieved.

.EXAMPLE
    PS> Show-VaultWrapping -Token s.yGdKDWpLBFYUPMbtnHZkmJZ7

    request_id     : b70f4c63-2c82-50e1-131f-3e34604d574a
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{creation_path=sys/wrapping/wrap; creation_time=2019-07-01T15:55:45.3618027-04:00; creation_ttl=216000}
    wrap_info      :
    warnings       :
    auth           :
#>
    [CmdletBinding()]
    param(
        #Specifies a token to retrieve wrapping information about.
        [Parameter(
            Position = 0
        )]
        [String] $Token,

        #Specifies how output information should be displayed in the console. Available options are JSON, PSObject or Hashtable.
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
        $jsonPayload = @"
{
    "token": "$Token"
}
"@

        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/wrapping/lookup"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Post'
            Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
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

Set-Alias -Name 'Lookup-VaultWrapping' -Value 'Show-VaultWrapping'