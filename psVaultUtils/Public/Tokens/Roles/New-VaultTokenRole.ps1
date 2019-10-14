function New-VaultTokenRole {
<#
.Synopsis
    Creates a new token role.    

.DESCRIPTION
    New-VaultTokenRole creates a new token role given a specified role name.

    Roles enforce specific behavior when creating tokens that allow token functionality that is otherwise not available or would require sudo/root privileges to access. 
    Role parameters, when set, override any provided options to the create endpoints.

    The role name is also included in the token path, allowing all tokens created against a role to be revoked using the /sys/leases/revoke-prefix endpoint.

.EXAMPLE
    PS> New-VaultTokenRole -RoleName 'nomad' -AllowedPolicies "dev" -Renewable:$true -AllowedEntityAliases "web-entity-alias","app-entity-*" -BoundCIDRs "127.0.0.1/32","128.252.0.0/16"

    This command does not produce any output.
#>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'  
    )]
    param(
        #Specifies the role whose configuration should be retrieved.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [String] $RoleName,

        [Parameter(
            Position = 1
        )]
        [String[]] $AllowedPolicies,

        [Parameter(
            Position = 2
        )]
        [String] $DisallowedPolicies,

        [Parameter(
            Position = 3
        )]
        [Switch] $Orphan,

        [Parameter(
            Position = 4
        )]
        [Bool] $Renewable = $true,

        [Parameter(
            Position = 5
        )]
        [String] $PathSuffix,

        [Parameter(
            Position = 6
        )]
        [String[]] $AllowedEntityAliases,

        [Parameter(
            Position = 7
        )]
        [String[]] $BoundCIDRs,

        [Parameter(
            Position = 8
        )]
        [ValidateScript({ $_ -match "^\d+$|^\d+[smh]$" })]
        [Alias('ExplicitMaxTTL')]
        [String] $ExplicitMaxTimeToLive,

        [Parameter(
            Position = 9
        )]
        [Switch] $NoDefaultPolicy,

        [Parameter(
            Position = 10
        )]
        [Alias('NumUses')]
        [Int] $NumberOfUses = 0,

        [Parameter(
            Position = 11
        )]
        [ValidateScript({ $_ -match "^\d+$|^\d+[smh]$" })]
        [String] $Period,

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
        if (Get-VaultTokenRole -RoleName $RoleName -ErrorAction 'SilentlyContinue') {
            Write-Error "The specified token role already exists. To modify a token role, use Update-VaultTokenRole."
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

        if ($PSCmdlet.ShouldProcess("$RoleName",'Create Vault token role')) {
            try {
                $result = Invoke-RestMethod @irmParams
            }
            catch {
                throw
            }
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