#Credit: https://4sysops.com/archives/convert-json-to-a-powershell-hash-table/
#This function is the result of reverse engineering ConvertTo-Hashtable, written by Adam Bertram

#BUG: ConvertFrom-Hashtable currently does not support pipeline input; 
#Sub-hashtables are not successfully converted to pscustomobjects.

function ConvertFrom-Hashtable {
<#
.Synopsis
    Converts a Hashtable into a PSObject.

.DESCRIPTION
    ConvertFrom-Hashtable converts a Hashtable into a PSObject.

    The function does not currently support pipeline input.

.EXAMPLE
    PS> $secret = Get-VaultKVSecret -Engine 'KVStore' -SecretsPath 'ServiceAccounts/DSCSvcAccount' -OutputType Hashtable

    PS> ConvertFrom-Hashtable $secret

    renewable      : False
    data           : @{metadata=; data=}
    warnings       :
    wrap_info      :
    request_id     : e7450e9e-e48c-e17d-8c16-db7d38790d64
    lease_duration : 0
    auth           :
    lease_id       :

    This example demonstrates converting a Hashtable to a PSObject. 
    The example is impractical because Get-VaultKVSecret supports returning results as PSObjects. 

#>
    [CmdletBinding()]
    [OutputType('pscustomobject')]
    param (
        [Parameter()]
        $InputObject
    )
 
    process {
        ## Return null if the input is null. This can happen when calling the function
        ## recursively and a property is null
        if ($null -eq $InputObject) {
            return $null
        }
 
        ## Check if the input is an array or collection. If so, we also need to convert
        ## those types into psobjects as well. This function will convert all child
        ## hashtables into psobjects (if applicable)
        if ($InputObject -is [pscustomobject] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject.GetEnumerator()) {
                    ConvertFrom-Hashtable -InputObject $object
                }
            )
 
            ## Return the array but don't enumerate it because the object may be pretty complex
            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [hashtable]) { ## If the hashtable has properties that need enumeration
            ## Convert it to its own hash table and return it as an object
            $hash = @{}
            foreach ($property in $InputObject.GetEnumerator()) { 
                $hash[$property.Name] = ConvertFrom-Hashtable -InputObject $property.Value
            }

            New-Object 'pscustomobject' -Property $hash
        } else {
            ## If the object isn't an array, collection, or other object, it's already a psobject
            ## So just return it.
            $InputObject
        }
    }
}