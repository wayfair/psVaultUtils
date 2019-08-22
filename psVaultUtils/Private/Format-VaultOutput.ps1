function Format-VaultOutput {
<#
.Synopsis
    Formats the result of Invoke-RestMethod call to Hashicorp Vault as a PSObject, Json String or Hashtable.

.DESCRIPTION
    Format-VaultOutput returns Vault data as a PSObject, Json String or Hashtable, depending on data type and data output specified by parent functions.

.EXAMPLE
    PS> $result

    request_id     : a916aa7e-4d25-4600-d059-cb5c901676f0
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{data=; metadata=}
    wrap_info      :
    warnings       :
    auth           :

    PS> $formatParams = @{
>>          InputObject = $result
>>          DataType    = 'secret_data'
>>          JustData    = $true
>>          OutputType  = 'Json'
>>      }

    PS> Format-VaultOutput $formatParams
    {
        "DOMAIN\sa_serviceAccount":  "s0mePassword!!"
    }


#>
    param(
        #Specifies the result of an Invoke-RestMethod call to a Hashicorp Vault instance.
        $InputObject,

        #Specifies a data type to assist with correctly accessing relevant properties when a -JustData parameter is passed.
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
            'random_bytes_data',
            'policy_data'
        )]
        [AllowNull()]
        [String] $DataType = $null,

        #Specifies how output information should be displayed in the console. Available options are JSON, PSObject or Hashtable.
        [ValidateSet('PSObject','Json','Hashtable')]
        [String] $OutputType,

        #Specifies whether or not just the data should be displayed in the console.
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
                        $command = { $InputObject.auth }
                    }
                    else {
                        $command = { $InputObject.wrap_info }
                    }
                }

                'data' {
                    $command = { $InputObject.data }
                }

                'auth' {
                    $command = { $InputObject.auth }
                }
                
                'secret_data' {
                    $command = { $InputObject.data.data }
                }
                
                'secret_metadata' {
                    $command = { $InputObject.data }
                }

                'metrics_gauges' {
                    $command = { $InputObject.Gauges }
                }

                'metrics_points' {
                    $command = { $InputObject.Points }
                }

                'metrics_counters' {
                    $command = { $InputObject.Counters }
                }

                'metrics_samples' {
                    $command = { $InputObject.Samples }
                }

                'login_token_data' {
                    $command = { $InputObject.auth | Select-Object 'client_token' }
                }

                'hash_data' {
                    $command = { $InputObject.data | Select-Object 'sum' }
                }

                'random_bytes_data' {
                    $command = { $InputObject.data | Select-Object 'random_bytes' }
                }

                'policy_data' {
                    $command = { $InputObject.data | Select-Object 'policies' }
                }

                'policy_data' {
                    $expression = '$InputObject.data | Select-Object policies'
                }
            }
    
            switch ($OutputType) {
                'PSObject' {
                    Invoke-Command -ScriptBlock $command
                }
    
                'Json' {
                    Invoke-Command -ScriptBlock $command | ConvertTo-Json
                }

                'Hashtable' {
                    Invoke-Command -ScriptBlock $command | ConvertTo-Hashtable
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