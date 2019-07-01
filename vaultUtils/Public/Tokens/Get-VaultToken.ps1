function Get-VaultToken {
    [CmdletBinding()]
    param(
        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject',

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
        $vaultAddr   = $global:VAULT_ADDR

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

            write-verbose "$vaultUsername"
            Write-Verbose "$($Credential.Username)"

            $irmParams = @{
                Uri    = "$vaultAddr/v1/auth/$($LoginMethod.ToLower())/login/$vaultUsername"
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