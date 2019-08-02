function Find-VaultTokenAccessor {
<#
.Synopsis
    Finds a string representing a token accessor, given a variety of different formats an object/JSON containing a token can come in.

.DESCRIPTION
    Find-VaultTokenAccessor extracts a string value that represents a token accessor, given a PSObject, snippet of JSON, or a raw string.

.EXAMPLE
    PS> New-Vaulttoken | Find-VaultTokenAccessor

    90kYrQP9YPJvKcIhc81OXnzQ

.EXAMPLE
    PS> Get-VaultToken -Self | Find-VaultTokenAccessor

    HNzZsGLIPKAhvRNPgonYnopV
#>
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true
        )]
        $Accessor
    )

    begin {

    }

    process {
        if ($Accessor -is [String]) {
            #Token is either String or Json-string

            try {
                $convertedAccessor = $Accessor | ConvertFrom-Json -ErrorAction Stop

                if ($convertedAccessor.auth.accessor) {
                    $iAccessor = $convertedAccessor.auth.accessor
                }
                elseif ($convertedAccessor.accessor) {
                    $iAccessor = $convertedAccessor.accessor
                }
                elseif ($convertedAccessor.data.id) {
                    $iAccessor = $convertedAccessor.data.accessor
                }
                else {
                    #This is not the Json you are looking for...
                    Write-Error "The specified JSON structure does not contain any properties that contain an accessor."
                    return
                }
            }
            catch {
                if ($Accessor -match "^[a-zA-Z0-9]{24}$") {
                    $iAccessor = $Accessor
                }
                else {
                    Write-Error "The specified string is malformed or otherwise could not be parsed as an accessor."
                    return
                }
                
            }
        }
        else {
            #Token is PSObject/Hashtable

            if ($Accessor.auth.accessor) {
                $iAccessor = $Accessor.auth.accessor
            }
            elseif ($Accessor.accessor) {
                $iAccessor = $Accessor.accessor
            }
            elseif ($Accessor.data.accessor) {
                $iAccessor = $Accessor.data.accessor
            }
            else {
                #This is not the PSObject you are looking for....
                Write-Error "The specified PSObject structure does not contain any properties that contain an accessor."
                return
            }
        }

        Write-Output $iAccessor
    }

    end {

    }
}