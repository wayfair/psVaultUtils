function Test-VaultSessionVariable {
    [CmdletBinding()]
    param(
        #Specifies one or more VAULT_ variables to 'CheckFor', to confirm it is populated.
        [ValidateSet('Cred','LoginMethod','Address','Token','Nodes')]
        [String[]] $CheckFor
    )

    begin {

    }

    process {
        $runSetVaultSessionVariable = $false
        $runGetSetVaultToken        = $false

        switch ($true) {
            ($CheckFor -contains 'Cred') {
                if (-not $global:VAULT_CRED) {
                    $runSetVaultSessionVariable = $true
                }
            }

            ($CheckFor -contains 'LoginMethod') {
                if (-not $global:VAULT_LOGIN_METHOD) {
                    $runSetVaultSessionVariable = $true
                }
            }

            ($CheckFor -contains 'Address') {
                if (-not $global:VAULT_ADDR) {
                    $runSetVaultSessionVariable = $true
                }
            }

            ($CheckFor -contains 'Nodes') {
                if (-not $global:VAULT_NODES) {
                    $runSetVaultSessionVariable = $true
                }
            }

            ($CheckFor -contains 'Token') {
                if (-not $global:VAULT_TOKEN) {
                    $runGetSetVaultToken = $true
                }
            }
        }

        if ($runSetVaultSessionVariable) {
            Set-VaultSessionVariable
        }

        if ($runGetSetVaultToken) {
            Get-VaultToken -JustToken | Set-VaultToken
        }
    }

    end {

    }
}