function New-VaultWrappedToken {
<#
.Synopsis
    Creates a new cubbyhole-wrapped vault token.

.DESCRIPTION
    New-VaultWrappedToken creates a one-time-use cubbyhole-wrapped vault token with a defined set of policies and a specified TimeToLive.

.EXAMPLE
    PS> New-VaultWrappedToken -WrapTimeToLive 24h -WrapPolicies log-rotation

    request_id     :
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           :
    wrap_info      : @{token=s.HgHYpkh2vdwqNHYntVUcOUdw; accessor=D9VwzmCgwxnFJfI8OiC8fvns; ttl=86400;
                    creation_time=2019-07-08T15:32:48.3010145-04:00; creation_path=auth/token/create;
                    wrapped_accessor=seR1NGStaC1ZA32F6R2fjeZj}
    warnings       :
    auth           :

.EXAMPLE 
    PS> New-VaultWrappedToken -WrapTimeToLive 24h -WrapPolicies log-rotation -OutputType Json -JustWrapInfo
    {
        "token":  "s.AxA5oyBExDI6XbJDOw2mSHaN",
        "accessor":  "ZJF3AowYEndIsUEM94OhFTIY",
        "ttl":  86400,
        "creation_time":  "2019-07-08T15:33:07.5482098-04:00",
        "creation_path":  "auth/token/create",
        "wrapped_accessor":  "84X3cWnCXIHGfExNxYF7IYyA"
    }
    
#>
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0
        )]
        [Alias('WrapTTL')]
        [String] $WrapTimeToLive = '24h',

        [Parameter(
            Position = 1
        )]
        [String[]] $WrapPolicies,

        #Specifies how output information should be displayed in the console. Available options are JSON, PSObject or Hashtable.
        [Parameter(
            Position = 2
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject',

        [Switch] $JustWrapInfo
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','RootToken'
    }

    process {
        $uri = $global:VAULT_ADDR

        #region Invoke the API

        $psobjPayload = [pscustomobject] @{
            policies = $WrapPolicies
        }

        $irmParams = @{
            Uri    = "$uri/v1/auth/token/create"
            Header = @{ 
                "X-Vault-Token"    = $global:VAULT_TOKEN
                "X-Vault-Wrap-TTL" = $WrapTimeToLive
            }
            Body   = $($psobjPayload | ConvertTo-Json -Compress)
            Method = 'Post'
        }

        try {
            $result = Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }

        #endregion

        #region Format Output

        $formatParams = @{
            InputObject = $result
            DataType    = 'wrap_info'
            JustData    = $JustWrapInfo.IsPresent
            OutputType  = $OutputType
        }

        Format-VaultOutput @formatParams

        #endregion
    }

    end {

    }
}