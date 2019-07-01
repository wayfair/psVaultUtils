function Set-VaultLoginToken {
<#
.Synopsis
    Assigns a specified token to VAULT_TOKEN.

.DESCRIPTION
    Assigns a specified vault token to the global variable VAULT_TOKEN.

    A vault token is used to authenticate to Vault. Without a valid token, most API endpoints cannot be interacted with.
    This function is almost always paired with Get-VaultToken; VAULT_TOKEN needs to set in order to utilize most funtions in vaultUtils.

.EXAMPLE
    PS> Set-VaultToken -Token s.J9CnwypEiNa6sPB20lmmxZh2 -Passthru

    Name                           Value
    ----                           -----
    VAULT_TOKEN                    s.J9CnwypEiNa6sPB20lmmxZh2

.EXAMPLE 
    PS> Get-Vaulttoken -JustToken | Set-VaultToken

    This command does not produce any output.
#>
    [CmdletBinding()]
    param(
        #Specifies a vault token to assign to VAULT_TOKEN.
        [Parameter(
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        $Token,

        #Specifies that the resulting VAULT_TOKEN variable should be displayed in the console.
        [Switch] $Passthru
    )

    begin {

    }

    process {
        if ($Token -is [String]) {
            #Token is either String or Json-string

            try {
                $convertedToken = $Token | ConvertFrom-Json -ErrorAction Stop

                if ($convertedToken.auth.client_token) {
                    $iToken = $convertedToken.auth.client_token
                }
                elseif ($convertedToken.client_token) {
                    $iToken = $convertedToken.client_token
                }
                else {
                    #This is not the Json you are looking for...
                    Write-Error "The specified JSON structure does not contain a property '.auth.client_token' or '.client_token'"
                    return
                }
            }
            catch {
                if ($Token -match "^s\..{24}$") {
                    $iToken = $Token
                }
                else {
                    Write-Error "The specified string is malformed or otherwise could not be parsed as a token."
                    return
                }
                
            }
        }
        else {
            #Token is PSObject

            if ($Token.auth.client_token) {
                $iToken = $Token.auth.client_token
            }
            elseif ($Token.client_token) {
                $iToken = $Token.client_token
            }
            else {
                #This is not the PSObject you are looking for....
                Write-Error "The specified PSObject structure does not contain a property '.auth.client_token' or '.client_token'"
            }
        }

        $global:VAULT_TOKEN = $iToken

        if ($Passthru) {
            Get-Variable -Name 'VAULT_TOKEN'
        }
    }

    end {

    }
}