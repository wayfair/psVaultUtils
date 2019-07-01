function Get-VaultWrapping {
<#
.Synopsis
    Retrieves a wrapped key-value pair, or series of key-value pairs, given a specified token.

.DESCRIPTION
    Get-VaultWrapping retrieves a wrapped key-value pair or collection of key-value pairs, given a specified wrapping token.

.EXAMPLE
    PS> Get-VaultWrapping -Token s.1G4mBRbpvZ7TQEj0Cf90MImO

    request_id     : fc90f091-39ed-e404-8e9f-d3361c450db6
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{foo=bar}
    wrap_info      :
    warnings       :
    auth           :
#>
    [CmdletBinding()]
    param(
        #Specifies a token that can unwrap wrapped data.
        [String] $Token,

        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the data should be displayed in the console.
        [Switch] $JustData
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
    }

    process {
        $jsonPayload = @"
{
    "token": "$Token"
}
"@

        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/wrapping/unwrap"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Post'
            Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
        }

        try {
            $result = Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }

        switch ($OutputType) {
            'Json' {
                if ($JustData) {
                    $result.data | ConvertTo-Json
                }
                else {
                    $result | ConvertTo-Json
                }
            }

            'PSObject' {
                if ($JustData) {
                    $result.data
                }
                else {
                    $result
                }
            }
        }
    }

    end {

    }
}

Set-Alias -Name 'Unwrap-VaultWrapping' -Value 'Get-VaultWrapping'