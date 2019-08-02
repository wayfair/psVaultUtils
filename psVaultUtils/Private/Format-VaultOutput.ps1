function Format-VaultOutput {
    param(
        $InputObject,

        [ValidateSet(
            'wrap_info',
            'data',
            'auth',
            'secret_data',
            'secret_metadata',
            'metrics_gauges',
            'metrics_points',
            'metrics_counters',
            'metrics_samples',
            'login_token_data',
            'hash_data',
            'random_bytes_data'
        )]
        [AllowNull()]
        [String] $DataType = $null,

        [ValidateSet('PSObject','Json','Hashtable')]
        [String] $OutputType,

        [Bool] $JustData
    )

    begin {

    }

    process {
        if ($JustData) {
            switch ($DataType) {
                'wrap_info' {
                    #if/else handles case where the result depends on the token 
                    #being specified in Get-VaultWrapping: 
                    #Vault-wrapped token from New-VaultWrappedToken vs wrapping token from New-VaultWrapping.
                    if ($null -eq $InputObject.wrap_info) {
                        $expression = '$InputObject.auth'
                    }
                    else {
                        $expression = '$InputObject.wrap_info'
                    }
                }

                'data' {
                    $expression = '$InputObject.data'
                }

                'auth' {
                    $expression = '$InputObject.auth'
                }
                
                'secret_data' {
                    $expression = '$InputObject.data.data'
                }
                
                'secret_metadata' {
                    $expression = '$InputObject.data'
                }

                'metrics_gauges' {
                    $expression = '$InputObject.Gauges'
                }

                'metrics_points' {
                    $expression = '$InputObject.Points'
                }

                'metrics_counters' {
                    $expression = '$InputObject.Counters'
                }

                'metrics_samples' {
                    $expression = '$InputObject.Samples'
                }

                'login_token_data' {
                    $expression = '$InputObject.auth | Select-Object client_token'
                }

                'hash_data' {
                    $expression = '$InputObject.data | Select-Object sum'
                }

                'random_bytes_data' {
                    $expression = '$InputObject.data | Select-Object random_bytes'
                }
            }
    
    
            switch ($OutputType) {
                'PSObject' {
                    Invoke-Expression $expression
                }
    
                'Json' {
                    Invoke-Expression $expression | ConvertTo-Json
                }

                'Hashtable' {
                    Invoke-Expression $expression | ConvertTo-Hashtable
                }
            }
        }
        else {
            switch ($OutputType) {
                'PSObject' {
                    $InputObject
                }

                'Json' {
                    $InputObject | ConvertTo-Json
                }

                'Hashtable' {
                    $InputObject | ConvertTo-Hashtable
                }
            }
        }
    }

    end {

    }
}