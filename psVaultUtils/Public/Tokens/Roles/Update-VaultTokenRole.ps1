function Update-VaultTokenRole {
<#
.Synopsis
    Modifies an existing token role.    

.DESCRIPTION
    Update-VaultTokenRole modifies an existing token role given a specified role name.

    Roles enforce specific behavior when creating tokens that allow token functionality that is otherwise not available or would require sudo/root privileges to access. 
    Role parameters, when set, override any provided options to the create endpoints.

    The role name is also included in the token path, allowing all tokens created against a role to be revoked using the /sys/leases/revoke-prefix endpoint.

.EXAMPLE
    PS> Get-VaultTokenRole -RoleName nomad -JustData

    allowed_policies    : {dev}
    disallowed_policies : {}
    explicit_max_ttl    : 0
    name                : nomad
    orphan              : False
    path_suffix         :
    period              : 0
    renewable           : False
    token_type          : default-service

    
    PS> Update-VaultTokenRole -RoleName nomad -Renewable:$true

    PS> Get-VaultTokenRole -RoleName nomad -JustData
    
    allowed_policies    : {dev}
    disallowed_policies : {}
    explicit_max_ttl    : 0
    name                : nomad
    orphan              : False
    path_suffix         :
    period              : 0
    renewable           : True
    token_type          : default-service

    
    Update-VaultTokenRole command does not produce any output.

#>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'  
    )]
    param(
        #Specifies the name of the token role being updated.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [String] $RoleName,

        #Specifies an array of policies that a token assigned to this role is allowed to use.
        [Parameter(
            Position = 1
        )]
        [String[]] $AllowedPolicies,

        #Specifies an array of policies that a token assigned to this role is not allowed to use. 
        [Parameter(
            Position = 2
        )]
        [String] $DisallowedPolicies,

        #Specifies whether a token assigned to the role should be an orphan or not Orphaned tokens do not have a parent token.
        [Parameter(
            Position = 3
        )]
        [Switch] $Orphan,

        #Specifies whether a token assigned to the role should be renewable or not.
        [Parameter(
            Position = 4
        )]
        [Bool] $Renewable = $true,

        #Specifies that tokens created with this role will be given a defined path suffix in addition to the role name.
        [Parameter(
            Position = 5
        )]
        [String] $PathSuffix,

        #Specifies a String or Json list of allowed entity alises.
        [Parameter(
            Position = 6
        )]
        [String[]] $AllowedEntityAliases,

        #Specifies a list of CIDR blocks (IP addresses which can authenticate successfully).
        [Parameter(
            Position = 7
        )]
        [String[]] $BoundCIDRs,

        #Specifies an explicit max TTL for tokens assigned to this role.
        [Parameter(
            Position = 8
        )]
        [ValidateScript({ $_ -match "^\d+$|^\d+[smh]$" })]
        [Alias('ExplicitMaxTTL')]
        [String] $ExplicitMaxTimeToLive,

        #Specifies that tokens assigned to this role should not get the 'Default' policy.
        [Parameter(
            Position = 9
        )]
        [Switch] $NoDefaultPolicy,

        #Specifies the number of uses a token assigned to this role should have.
        [Parameter(
            Position = 10
        )]
        [Alias('NumUses')]
        [Int] $NumberOfUses = 0,

        #Specifies a period of time set on the token role.
        [Parameter(
            Position = 11
        )]
        [ValidateScript({ $_ -match "^\d+$|^\d+[smh]$" })]
        [String] $Period,

        #Specifies the type of token that should be created.
        [Parameter(
            Position = 12
        )]
        [ValidateSet('Default','Service','Batch')]
        [String] $TokenType
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        if (-not $(Get-VaultTokenRole -RoleName $RoleName -ErrorAction 'SilentlyContinue')) {
            Write-Error "The specified token role does not exist. To create a new token role, use New-VaultTokenRole."
            return
        }

        $uri = $global:VAULT_ADDR

        #region Build the Payload

        $psobjPayload = @{}

        $psObjPayload += @{ role_name = $RoleName }

        if ($AllowedPolicies) {
            $psobjPayload += @{ allowed_policies = @($AllowedPolicies) }
        }

        if ($DisallowedPolicies) {
            $psobjPayload += @{ disallowed_policies = @($DisallowedPolicies) }
        }

        if ($Orphan) {
            $psobjPayload += @{ orphan = $true }
        }
        else {
            $psobjPayload += @{ orphan = $false }
        }

        if ($Renewable) {
            $psobjPayload += @{ renewable = $true }
        }
        else {
            $psobjPayload += @{ renewable = $false }
        }

        if ($PathSuffix) {
            $psobjPayload += @{ path_suffix = $PathSuffix }
        }

        if ($AllowedEntityAliases) {
            $psobjPayload += @{ allowed_entity_aliases = @($AllowedEntityAliases) }
        }

        if ($BoundCIDRs) {
            $psobjPayload += @{ token_bound_cidrs = @($BoundCIDRs) }
        }

        if ($ExplicitMaxTimeToLive) {
            $psobjPayload += @{ token_explicit_max_ttl = $ExplicitMaxTimeToLive }
        }

        if ($NoDefaultPolicy) {
            $psobjPayload += @{ token_no_default_policy = $true }
        }
        else {
            $psobjPayload += @{ token_no_default_policy = $false }
        }

        if ($NumberOfUses) {
            $psobjPayload += @{ token_num_uses = $NumberOfUses }
        }

        if ($Period) {
            $psobjPayload += @{ token_period = $Period }
        }

        if ($TokenType) {
            $psobjPayload += @{ token_type = $TokenType }
        }

        #endregion

        $jsonPayload = $([pscustomobject] $psobjPayload) | ConvertTo-Json #-Compress

        $irmParams = @{
            Uri    = "$uri/v1/auth/token/roles/$RoleName"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Post'
            Body   = $jsonPayload
        }

        if ($PSCmdlet.ShouldProcess("$RoleName",'Update Vault token role')) {
            try {
                Invoke-RestMethod @irmParams
            }
            catch {
                throw
            }
        }
    }

    end {

    }
}