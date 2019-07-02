function New-VaultToken {
<#
.Synopsis
    Create a new Vault token.

.DESCRIPTION
    New-VaultToken is used to create a new Vault token.

    If the calling token is not a root token, the following parameters are ignored or are otherwise unavailable:
        * TokenID
        * NoParent
    
    If the Orphan flag is specified, a token can be created without a parent. A root token is not required to create an orphaned token.

.EXAMPLE
    PS> New-VaultToken -OutputType Json

    {
        "request_id":  "11abca5c-ad31-50b9-eabc-b6a144e7509a",
        "lease_id":  "",
        "renewable":  false,
        "lease_duration":  0,
        "data":  null,
        "wrap_info":  null,
        "warnings":  null,
        "auth":  {
                    "client_token":  "s.VzvlPUsnox1CtGAQfHiEEW6s",
                    "accessor":  "6IrkurVLrzXx9TBev9muEtq2",
                    "policies":  [
                                    "default",
                                    "jenkinsc02-secret-consumer",
                                    "operator"
                                ],
                    "token_policies":  [
                                            "default"
                                        ],
                    "identity_policies":  [
                                            "jenkinsc02-secret-consumer",
                                            "operator"
                                        ],
                    "metadata":  null,
                    "lease_duration":  129600,
                    "renewable":  false,
                    "entity_id":  "357f788d-75cf-c16d-f6d9-cdbd6c5deee8",
                    "token_type":  "service",
                    "orphan":  false
                }
    }

    A new token can be created without specifying any parameters. 
    Default values are based either the parent token (VAULT_TOKEN) or default parameter values defined in Hashicorp Vault documentation.

.EXAMPLE
    PS> $newTokenParams = @{
    >>        RoleName = 'SomeRole'
    >>        Policies = 'jenkinsc02-secret-consumer'
    >>        MetaData = @{ 'user'='bsmall' }
    >>        Renewable = $true
    >>        TimeToLive = "48h"
    >>        DisplayName = "bsmall"
    >>        NumberOfUses = 10
    >>    }

    PS> New-VaultToken @newTokenParams

    request_id     : ec54b2f4-c538-d102-3273-6b7215cc2ba6
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           :
    wrap_info      :
    warnings       :
    auth           : @{client_token=s.Ezg2ZSLaKcs8g3I32BQrBU3H; accessor=xa06uj4p0vaVMcpYrVHviw1Y; policies=System.Object[];
                    token_policies=System.Object[]; identity_policies=System.Object[]; metadata=; lease_duration=172800;
                    renewable=True; entity_id=357f788d-75cf-c16d-f6d9-cdbd6c5deee8; token_type=service; orphan=False}\

    * This token utilizes a subset of the parent token's policies.
    * Metadata, which can be found in the audit logs, is associated with the token's actions.
    * The token is renewable
    * It has a lease/ttl of 48 hours.
    * It has a displayname of "token-bsmall". "token-" is automatically prefixed on the displayname.
    * The token can be used 10 times within the 48 hours before it expires.

.EXAMPLE
    PS> New-VaultToken -Orphan -OutputType Json
    {
        "request_id":  "bb55a12a-d6a1-8353-ed9f-c27bd2961c95",
        "lease_id":  "",
        "renewable":  false,
        "lease_duration":  0,
        "data":  null,
        "wrap_info":  null,
        "warnings":  null,
        "auth":  {
                    "client_token":  "s.YYvh7P9FWNSoOoxpWiEqVUny",
                    "accessor":  "dNR6J5Av95Kttj26aQQ8ayM6",
                    "policies":  [
                                    "default"
                                ],
                    "token_policies":  [
                                            "default"
                                        ],
                    "metadata":  null,
                    "lease_duration":  129600,
                    "renewable":  false,
                    "entity_id":  "",
                    "token_type":  "service",
                    "orphan":  true
                }
    }

    * This token is orphaned. 
    * It contains no policies that the caller token has.
    * The token is not renewable, and has a default lease/ttl.

#>
    [CmdletBinding()]
    param(
        #Specifies the ID of the client token. This parameter can only be specified if VAULT_TOKEN is a root token; It will otherwise be ignored.
        [Parameter(
            Position = 0
        )]
        [String] $TokenID,

        #Specifies the name of the token role.
        [Parameter(
            Position = 1
        )]
        [String] $RoleName,

        #Specifies a list of policies for the token. The specified policies must be a subset of the policies belonging to the token making the request, unlessroot.
        #If not specified, the generated token will have all of the capabilities of the calling token.
        [Parameter(
            Position = 2
        )]
        [String[]] $Policies,

        #Specifies a map of string to string valued metadata. This data is passed through to audit devices.
        [Parameter(
            Position = 3
        )]
        [Hashtable] $Metadata,

        #Specifies whether or not the token will have a parent. A token must have a parent unless it is called from a root token, and NoParent is true.
        [Parameter(
            Position = 4
        )]
        [Switch] $NoParent,

        #Specifies that the 'default' policy should not be included in the token's policy set.
        [Parameter(
            Position = 5
        )]
        [Switch] $NoDefaultPolicy,

        #Specifies the ability to enable or disable whether or not a token can be renewed past its initial TimeToLive. 
        #A renewable token can be renewed up to the system/mount maximum TimeToLive.
        [Parameter(
            Position = 6
        )]
        [Bool] $Renewable,

        #Specifies the TimeToLive period of the token, provided as "1h" where hour is the largest suffix. 
        #If not provided, the token is valid for the deault lease TimeToLive, or indefinitely if the root policy is used.
        [Parameter(
            Position = 7
        )]
        [Alias('TTL')]
        [String] $TimeToLive,

        #Specifies that a token will have a max TimeToLive set on it. A token with a configured Max TimeToLive cannot be renewed past the specified value.
        [Parameter(
            Position = 8
        )]
        [Alias('ExplicitMaxTTL')]
        [String] $ExplicitMaxTimeToLive,

        #Specifies a display name or friendly name for a token.
        [Parameter(
            Position = 9
        )]
        [String] $DisplayName,

        #Specifies the number of uses a token has. Defaults to 0, meaning a token has no limit on the number of uses.
        [Parameter(
            Position = 10
        )] 
        [Alias('NumUses')]
        [Int] $NumberOfUses = 0,

        #Specifies that the token will be periodic; It will have no max TimeToLive (unless Explicit Max TimeToLive is specified), but every renewal will use the given period.
        #This parameter requires a root/sudo token to use.
        [Parameter(
            Position = 11
        )]
        [String] $Period,

        #Specifies that the created token should be an orphan (not be the child of a parent token).
        [Parameter(
            Position = 12
        )]
        [Switch] $Orphan,

        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 13
        )]
        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the auth data should be displayed in the console.
        [Parameter(
            Position = 14
        )]
        [Switch] $JustAuth
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'LoginMethod','Cred','Address','Token', 'RootToken'
    }

    process {
        $uri = $global:VAULT_ADDR
        
        #region Build the Payload

        $psobjPayload = @{}

        if ($global:VAULT_ROOT_TOKEN_STATUS) {
            $psobjPayload += @{ 'id' = $TokenID }
        }

        if ($RoleName) {
            $psobjPayload += @{ 'role_name' = $RoleName }
        }

        if ($Policies) {
            $psobjPayload += @{ 'policies' = $Policies }
        }

        if ($MetaData) {
            $psobjPayload += @{ 'meta' = $Metadata }
        }

        if ($Orphan) {
            $fulluri = "$uri/v1/auth/token/create-orphan"
            
            #NoParent is ignored when creating an orphaned token.
        }
        else {
            $fulluri = "$uri/v1/auth/token/create"

            if ($global:VAULT_ROOT_TOKEN_STATUS -and $NoParent.IsPresent) {
                $psobjPayload += @{ 'no_parent' = $NoParent }
            }
        }

        if ($NoDefaultPolicy) {
            $psobjPayload += @{ 'no_default_policy' = $NoDefaultPolicy.IsPresent }
        }

        $psobjPayload += @{ 'renewable' = $Renewable }

        if ($TimeToLive) {
            $psobjPayload += @{ 'ttl' = $TimeToLive }
        }

        if ($ExplicitMaxTimeToLive) {
            $psobjPayload += @{ 'explicit_max_ttl' = $ExplicitMaxTimeToLive }
        }

        if ($DisplayName) {
            $psobjPayload += @{ 'display_name' = $DisplayName }
        }

        if ($NumberOfUses) {
            $psobjPayload += @{ 'num_uses' = $NumberOfUses }
        }

        if ($Period) {
            $psobjPayload += @{ 'period' = $Period }
        }

        #endregion

        #region Invoke the API

        $jsonPayload = $([pscustomobject] $psobjPayload) | ConvertTo-Json -Compress

        $irmParams = @{
            Uri    = $fulluri
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Body   = $jsonPayload
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

        switch ($OutputType) {
            'Json' {
                if ($JustAuth) {
                    $result.auth | ConvertTo-Json
                }
                else {
                    $result | ConvertTo-Json
                }
            }

            'PSObject' {
                if ($JustAuth) {
                    $result.auth
                }
                else {
                    $result
                }
            }
        }

        #endregion
    }

    end {

    }
}