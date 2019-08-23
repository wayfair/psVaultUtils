function Get-VaultTokenAccessor {
<#
.Synopsis
    Retrieves information about a vault token, given its accessor.

.DESCRIPTION
    Get-VaultTokenAccessor retrieves information about a specified client vault token via its accessor.

    This function can/should be used when the actual token ID is unknown.

.EXAMPLE
    PS> Get-VaultTokenAccessor -Accessor uJDuXRNGtBttnkmh3ZJu285K

    request_id     : bfd263e8-10c7-3e6f-6ace-cf7ebd2113f7
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{accessor=uJDuXRNGtBttnkmh3ZJu285K; creation_time=1562012821; creation_ttl=129600;
                    display_name=ldap-dev-ben.small; entity_id=357f788d-75cf-c16d-f6d9-cdbd6c5deee8;
                    expire_time=2019-07-03T04:27:01.3416702-04:00; explicit_max_ttl=0; external_namespace_policies=; id=;
                    identity_policies=System.Object[]; issue_time=2019-07-01T16:27:01.3416702-04:00; meta=; num_uses=0;
                    orphan=True; path=auth/ldap/login/dev-ben.small; policies=System.Object[]; renewable=True; ttl=128337;
                    type=service}
    wrap_info      :
    warnings       :
    auth           :

.EXAMPLE 
    PS> Get-VaultTokenAccessor -Accessor uJDuXRNGtBttnkmh3ZJu285K -JustData -OutputType Json
    {
        "accessor":  "uJDuXRNGtBttnkmh3ZJu285K",
        "creation_time":  1562012821,
        "creation_ttl":  129600,
        "display_name":  "ldap-dev-ben.small",
        "entity_id":  "357f788d-75cf-c16d-f6d9-cdbd6c5deee8",
        "expire_time":  "2019-07-03T04:27:01.3416702-04:00",
        "explicit_max_ttl":  0,
        "external_namespace_policies":  {

                                        },
        "id":  "",
        "identity_policies":  [
                                "jenkinsc02-secret-consumer",
                                "operator"
                            ],
        "issue_time":  "2019-07-01T16:27:01.3416702-04:00",
        "meta":  {
                    "username":  "dev-ben.small"
                },
        "num_uses":  0,
        "orphan":  true,
        "path":  "auth/ldap/login/dev-ben.small",
        "policies":  [
                        "default"
                    ],
        "renewable":  true,
        "ttl":  128294,
        "type":  "service"
    }

#>
    [CmdletBinding()]
    param(
        #Specifies a token accessor to retrieve information about.
        [Parameter(
            ValueFromPipeline = $true,
            Position = 0
        )]
        $Accessor,

        #Specifies how output information should be displayed in the console. Available options are JSON, PSObject or Hashtable.
        [Parameter(
            Position = 1
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the token should be displayed in the console.
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

        $jsonPayload = @"
{
    "accessor": "$($Accessor | Find-VaultTokenAccessor)"
}
"@

        $irmParams = @{
            Uri    = "$uri/v1/auth/token/lookup-accessor"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
            Method = 'Post'
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