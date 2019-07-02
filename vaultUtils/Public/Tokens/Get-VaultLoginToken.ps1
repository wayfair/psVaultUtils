function Get-VaultLoginToken {
<#
.Synopsis
    Retrieves a token that can be used to authenticate to Vault.

.DESCRIPTION
    Retrives a vault token, given already-defined variables: VAULT_ADDR, VAULT_CRED and VAULT_LOGIN_METHOD.

    A vault token is used to authenticate to Vault. Without a valid token, most API endpoints cannot be interacted with.
    This function is almost always paired with Set-VaultLoginToken; VAULT_TOKEN needs to set in order to utilize most funtions in vaultUtils.

.EXAMPLE
    PS> Get-VaultLoginToken

    request_id     : f77d1e9e-29a0-3daf-a0a3-96fbce9e28e8
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           :
    wrap_info      :
    warnings       :
    auth           : @{client_token=s.9mQvNcxWiYRfNBetJRD4Ofrq; accessor=nN2uATI7eiY3wIciLwYBJhkG; policies=System.Object[];
                    token_policies=System.Object[]; identity_policies=System.Object[]; metadata=; lease_duration=129600;
                    renewable=True; entity_id=357f788d-75cf-c16d-f6d9-cdbd6c5deee8; token_type=service; orphan=True}

.EXAMPLE 
    PS> Get-VaultLoginToken -JustToken

    client_token
    ------------
    s.J9CnwypEiNa6sPB20lmmxZh2

.EXAMPLE
    PS> Get-VaultLoginToken | Set-VaultLoginToken

    This command authenticates to vault using credentials and login method defined in VAULT_CRED and VAULT_LOGIN_METHOD,
    and then passes the resulting object to Set-VaultLoginToken, which assigns the token to VAULT_TOKEN.
#>
    [CmdletBinding()]
    param(
        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the token should be displayed in the console.
        [Switch] $JustToken
    )

    begin {
        Try {
            Stop-Transcript
            Write-Warning "A running Transcript was stopped to prevent writing token information to disk."
        }
        Catch {
            #Transcript was not running.
        }

        Test-VaultSessionVariable -CheckFor 'LoginMethod','Cred','Address'     
    }

    process {
        $LoginMethod = $global:VAULT_LOGIN_METHOD
        $Credential  = $global:VAULT_CRED
        $uri         = $global:VAULT_ADDR

        if ($Credential) {
            $jsonPayload = @"
{
    "password": "$($Credential.GetNetworkCredential().Password)"
}
"@

            if ($Credential.Username -match "\\") {
                $vaultUsername = $Credential.Username -split "\\" | Select-Object -Skip 1 -First 1
            }
            else {
                $vaultUsername = $Credential.Username
            }

            $irmParams = @{
                Uri    = "$uri/v1/auth/$($LoginMethod.ToLower())/login/$vaultUsername"
                Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
                Method = 'Post'
            }

            try {
                $result = Invoke-RestMethod @irmParams
            }
            catch {
                throw
            }

            switch ($OutputType) {
                'Json' {
                    if ($JustToken) {
                        $result.auth | Select-Object 'client_token' | ConvertTo-Json
                    }
                    else {
                        $result | ConvertTo-Json
                    }
                }

                'PSObject' {
                    if ($JustToken) {
                        [pscustomobject] @{
                            'client_token' = $result.auth.client_token
                        }
                    }
                    else {
                        $result
                    }
                }
            }
        }
    }

    end {
        #Delete all traces of variables that could contain a plaintext password.
        $jsonPayload = $null
        $irmParams   = $null
        [System.GC]::Collect()
    }
}