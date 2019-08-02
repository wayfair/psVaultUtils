function Find-VaultToken {
<#
.Synopsis
    Finds a string representing a token, given a variety of different formats an object/JSON containing a token can come in.

.DESCRIPTION
    Find-VaultToken extracts a string value that represents a token ID, given a PSObject, snippet of JSON, or a raw string.

.EXAMPLE
    PS> $token = New-VaultToken

    PS> $token | Find-VaultToken

    s.2DSGl9szi0KkIpa53eoFWO4s

.EXAMPLE
    PS> $token = New-VaultToken -JustAuth -OutputType Json

    PS> $token | Find-VaultToken

    s.2DFMncXbX1rFQX3M4KitesGd
#>
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true
        )]
        $Token
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
                elseif ($convertedToken.data.id) {
                    $iToken = $convertedToken.data.id
                }
                elseif ($convertedToken.id) {
                    $iToken = $convertedToken.id
                }
                else {
                    #This is not the Json you are looking for...
                    Write-Error "The specified JSON structure does not contain any properties that contain a token."
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
            #Token is PSObject/Hashtable

            if ($Token.auth.client_token) {
                $iToken = $Token.auth.client_token
            }
            elseif ($Token.client_token) {
                $iToken = $Token.client_token
            }
            elseif ($Token.data.id) {
                $iToken = $Token.data.id
            }
            elseif ($Token.id) {
                $iToken = $Token.id
            }
            else {
                #This is not the PSObject you are looking for....
                Write-Error "The specified PSObject structure does not contain any properties that contain a token."
                return
            }
        }

        Write-Output $iToken
    }

    end {

    }
}