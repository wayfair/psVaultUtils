function Get-VaultWrapping {
<#
.Synopsis
    Retrieves a wrapped key-value pair, series of key-value pairs or vault-wrapped token, given a specified token.

.DESCRIPTION
    Get-VaultWrapping retrieves a wrapped key-value pair, collection of key-value pairs, or a vault-wrapped token, given a specified wrapping token.

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

.EXAMPLE
    PS> Get-VaultWrapping -Token s.2Dx7RLfOFg4E90p1oFeQR4C1 -IsWrappingToken

    request_id     : 6f2cf0ab-0a8e-d475-c24a-bea085cb1d2a
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           :
    wrap_info      :
    warnings       :
    auth           : @{client_token=s.NVKrGA1rzMoY9UZD2Ca50BOx; accessor=X1WvPXClCeMUPR1S8uxhZGRe; policies=System.Object[];
                    token_policies=System.Object[]; identity_policies=System.Object[]; metadata=; lease_duration=129600;
                    renewable=True; entity_id=357f788d-75cf-c16d-f6d9-cdbd6c5deee8; token_type=service; orphan=False}

    This example demonstrates the retrieval of a vault-wrapped token. 
    Notably (but not shown) a VAULT_TOKEN does not need to be set to retrive a vault-wrapped token.
#>
    [CmdletBinding()]
    param(
        #Specifies a token that can unwrap wrapped data.
        [Parameter(
            Position = 0
        )]
        [String] $Token,

        #Specifies that the token being specified is an unwrapping token.
        [Parameter(
            Position = 1
        )]
        [Switch] $IsWrappingToken,

        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 2
        )]
        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the data should be displayed in the console.
        [Parameter(
            Position = 3
        )]
        [Switch] $JustData
    )

    begin {
        #If the token being specified is a wrapping token, we only need an address.
        if ($IsWrappingToken) {
            Test-VaultSessionVariable -CheckFor 'Address'
        }
        else {
            Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
        }
    }

    process {
        $uri = $global:VAULT_ADDR

        $jsonPayload = @"
{
    "token": "$Token"
}
"@

        $irmParams = @{
            Uri    = "$uri/v1/sys/wrapping/unwrap"
            Method = 'Post'
        }


        if ($IsWrappingToken) {
            $irmParams += @{ 
                Header = @{ "X-Vault-Token" = $Token }
            }
        }
        else {
            $irmParams += @{ 
                Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
                Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
            }
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