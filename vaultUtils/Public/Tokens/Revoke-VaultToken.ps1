function Revoke-VaultToken {
<#
.Synopsis
    Revokes a token and all child tokens.

.DESCRIPTION
    Revoke-VaultToken revokes a token and all tokens that are children of the token. 
    When a token is revoked, all dynamic secrets generated with it are also revoked.

    If the Orphan flag is specified. child tokens are NOT revoked, and are instead orphaned.

.EXAMPLE 
    PS> Revoke-VaultToken -Token s.48hb1N2nAvvK83n3YZcng9AT

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "Revoke Vault token" on target "s.48hb1N2nAvvK83n3YZcng9AT".
    [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): y

    This example demonstrates revoking a token.

    This command does not produce any output.

.EXAMPLE
    PS> Revoke-VaultToken -Self -Confirm:$false

    This example demonstrates revoking your own token - the token defined in VAULT_TOKEN. 
    The Confirm flag is set to FALSE making no additional input required.

    This command does not produce any output.

.EXAMPLE
    PS> Revoke-VaultToken -Token s.48hb1N2nAvvK83n3YZcng9AT -OrphanChildren -Confirm:$false

    This example demonstrates revoking a toke, but not any child tokens that were associated with the specified token.

    This command does not produce any output.

#>
    [CmdletBinding(
        DefaultParameterSetName = 'bySelf',
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        #Specifies a token to revoke.
        [Parameter(
            ParameterSetName = 'byToken',
            Position = 0
        )]
        [String] $Token,

        #Specifies that the token revoked should be the token defined in VAULT_TOKEN.
        [Parameter(
            ParameterSetName = 'bySelf',
            Position = 1
        )]
        [Switch] $Self,

        #Specifies that the given token should be revoked, and any child tokens spawned by the given token should be orphaned.
        [Parameter(
            ParameterSetName = 'byToken',
            Position = 2
        )]
        [Switch] $OrphanChildren
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'LoginMethod','Cred','Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        switch ($PSCmdlet.ParameterSetName) {
            'bySelf' {
                $iToken      = $global:VAULT_TOKEN
                $fulluri     = "$uri/v1/auth/token/revoke-self"
                $method      = 'Post'
            }
            'byToken' {
                $iToken      = $token

                if ($OrphanChildren) {
                    $fulluri = "$uri/v1/auth/token/revoke-orphan"
                }
                else {
                    $fulluri = "$uri/v1/auth/token/revoke"
                }

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

        if ($PSCmdlet.ShouldProcess("$iToken",'Revoke Vault token')) {
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