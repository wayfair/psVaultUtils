<#
Sets $global:VAULT_TOKEN to a Vault Token.
#>
function Set-VaultToken {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true
        )]
        $Token,

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
                    Write-Error "The specified JSON structure does not contain a path '.auth.client_token' or '.client_token'"
                    return
                }
            }
            catch {
                Write-Error "The specified JSON is malformed or otherwise could not be converted into a PSObject."
                return
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