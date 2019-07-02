function Test-VaultSessionVariable {
    [CmdletBinding()]
    param(
        #Specifies one or more VAULT_ variables to 'CheckFor', to confirm it is populated.
        [ValidateSet('Cred','LoginMethod','Address','Token','Nodes','RootToken')]
        [String[]] $CheckFor
    )

    begin {

    }

    process {
        $runSetVaultSessionVariable = $false
        $runGetSetVaultToken        = $false
        $runGetVaultToken           = $false

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

            ($CheckFor -contains 'RootToken') {
                if (-not $global:VAULT_ROOT_TOKEN_STATUS) {
                    $runGetVaultToken = $true
                }
            }
        }

        if ($runSetVaultSessionVariable) {
            Set-VaultSessionVariable
        }

        if ($runGetSetVaultToken) {
            Get-VaultLoginToken -JustToken | Set-VaultLoginToken
        }

        if ($runGetVaultToken) {
            $policies = Get-VaultToken -Token $global:VAULT_TOKEN -JustData | 
                Select-Object -ExpandProperty 'policies'

            if ($policies -contains "root") {
                $global:VAULT_ROOT_TOKEN_STATUS = $true
            }
            else {
                $global:VAULT_ROOT_TOKEN_STATUS = $false
            }
        }
    }

    end {

    }
}