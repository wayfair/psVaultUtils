function Update-VaultWrapping {
<#
.Synopsis
    Rewraps wrapped data with a new token, thus refreshing its TTL.

.DESCRIPTION
    Update-VaultWrapping rewraps wrapped data with a new token, refreshing the TTL of the token in the process.

    The old token is invalidated.

    This can be used for long-term storage of a secret in a response-wrapped token when rotation is a requirement.

.EXAMPLE
    PS> Update-VaultWrapping -Token s.yGdKDWpLBFYUPMbtnHZkmJZ7

    request_id     :
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           :
    wrap_info      : @{token=s.oYgKq8URLMmyIr9vBCCixaeR; accessor=Wg827LaoZLQESPXhFs4jjSQe; ttl=216000;
                    creation_time=2019-07-01T16:01:46.0137524-04:00; creation_path=sys/wrapping/wrap}
    warnings       :
    auth           :
#>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'   
    )]
    param(
        #Specifies a token whose wrapped data should be rewrapped.
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
            Uri    = "$uri/v1/sys/wrapping/rewrap"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Post'
            Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
        }

        if ($PSCmdlet.ShouldProcess("$Token",'Update Vault wrapping')) {
            try {
                $result = Invoke-RestMethod @irmParams
            }
            catch {
                throw
            }
        }

        $formatParams = @{
            InputObject = $result
            DataType    = 'wrap_info'
            JustData    = $JustData.IsPresent
            OutputType  = $OutputType
        }

        Format-VaultOutput @formatParams
    }

    end {

    }
}

Set-Alias -Name 'Rewrap-VaultWrapping' -Value 'Update-VaultWrapping'