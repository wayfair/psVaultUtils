function Get-VaultToken {
<#
.Synopsis
    Retrieves information about a vault token.

.DESCRIPTION
    Get-VaultToken retrieves information about a specified client vault token.

.EXAMPLE
    PS> Get-VaultToken -Self -JustData -OutputType Json
    {
        "accessor":  "uJDuXRNGtBttnkmh3ZJu285K",
        "creation_time":  1562012821,
        "creation_ttl":  129600,
        "display_name":  "ldap-dev-bsmall",
        "entity_id":  "357f788d-75cf-c16d-f6d9-cdbd6c5deee8",
        "expire_time":  "2019-07-03T04:27:01.3416702-04:00",
        "explicit_max_ttl":  0,
        "external_namespace_policies":  {

                                        },
        "id":  "s.FFrnIPyWvtOU4J1MhFWEU6ZE",
        "identity_policies":  [
                                "jenkinsc02-secret-consumer",
                                "operator"
                            ],
        "issue_time":  "2019-07-01T16:27:01.3416702-04:00",
        "meta":  {
                    "username":  "dev-bsmall"
                },
        "num_uses":  0,
        "orphan":  true,
        "path":  "auth/ldap/login/dev-bsmall",
        "policies":  [
                        "default"
                    ],
        "renewable":  true,
        "ttl":  128694,
        "type":  "service"
    }

.EXAMPLE 
    PS> Get-VaultToken -Token s.TNzW1cvYZGzO2evwuFjGgK3G -OutputType Json
    {
        "request_id":  "f108a64b-db21-85d5-43a3-bc1504ede952",
        "lease_id":  "",
        "renewable":  false,
        "lease_duration":  0,
        "data":  {
                    "accessor":  "G3GVdpFnAsy1fBzVvkAzDA7e",
                    "creation_time":  1562013557,
                    "creation_ttl":  72000,
                    "display_name":  "",
                    "entity_id":  "",
                    "expire_time":  "2019-07-02T12:39:17.8800713-04:00",
                    "explicit_max_ttl":  72000,
                    "id":  "s.TNzW1cvYZGzO2evwuFjGgK3G",
                    "issue_time":  "2019-07-01T16:39:17.8800713-04:00",
                    "meta":  null,
                    "num_uses":  1,
                    "orphan":  true,
                    "path":  "sys/wrapping/wrap",
                    "policies":  [
                                    "response-wrapping"
                                ],
                    "renewable":  false,
                    "ttl":  71862,
                    "type":  "service"
                },
        "wrap_info":  null,
        "warnings":  null,
        "auth":  null
    }

    In this example, information about a wrapping token is retrieved.

#>
    [CmdletBinding(
        DefaultParameterSetName = 'bySelf'
    )]
    param(
        #Specifies a token to retrieve information about.
        [Parameter(
            ParameterSetName = 'byToken',
            ValueFromPipeline = $true,
            Position = 0
        )]
        $Token,

        #Specifies that the token received should be token defined in VAULT_TOKEN.
        [Parameter(
            ParameterSetName = 'bySelf',
            Position = 1
        )]
        [Switch] $Self,

        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 2
        )]
        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the token should be displayed in the console.
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

        switch ($PSCmdlet.ParameterSetName) {
            'bySelf' {
                $iToken      = $global:VAULT_TOKEN
                $fulluri     = "$uri/v1/auth/token/lookup-self"
                $method      = 'Get'
            }
            'byToken' {
                $iToken      = $($Token | Find-VaultToken)
                $fulluri     = "$uri/v1/auth/token/lookup"
                $method      = 'Post'
                $jsonPayload = @"
{
    "token": "$iToken"
}
"@
            }
        }

        $irmParams = @{
            Uri    = $fulluri
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = $method
        }

        if ($PSCmdlet.ParameterSetName -eq 'byToken') {
            $irmParams += @{Body = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress) }
        }

        try {
            $result = Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }

        switch ($OutputType) {
            'Json' {
                if ($JustData) {
                    $result.data | ConvertTo-Json
                }
                else {
                    $result | ConvertTo-Json
                }
            }

            'PSObject' {
                if ($JustData) {
                    $result.data
                }
                else {
                    $result
                }
            }
        }
    }

    end {

    }
}