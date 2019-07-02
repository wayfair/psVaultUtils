function Revoke-VaultTokenAccessor {
<#
.Synopsis
    Revokes a token and all child tokens, via the token's accessor.

.DESCRIPTION
    Revoke-VaultTokenAccessor revokes a token and all tokens that are children of the token. 
    When a token is revoked, all dynamic secrets generated with it are also revoked.

    This is meant for purposes where there is no access to the tokenID, but there is a need to revoke the token and its children.

.EXAMPLE 
    PS> Revoke-VaultTokenAccesor -Accessor hDGapzslOYnX7wgpsLNsIAzz

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "Revoke Vault token accessor" on target "hDGapzslOYnX7wgpsLNsIAzz".
    [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): y

    This example demonstrates revoking a token accessor.

    This command does not produce any output.

#>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        #Specifies a token accessor to revoke.
        [Parameter(
            ValueFromPipeline = $true,
            Position = 0
        )]
        $Accessor
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'LoginMethod','Cred','Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        $acc = $($Accessor | Find-VaultTokenAccessor)

        $jsonPayload = @"
{
    "accessor": "$acc"
}
"@

        $irmParams = @{
            Uri    = "$uri/v1/auth/token/revoke-accessor"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
            Method = 'Post'
        }

        if ($PSCmdlet.ShouldProcess("$acc",'Revoke Vault token accessor')) {
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