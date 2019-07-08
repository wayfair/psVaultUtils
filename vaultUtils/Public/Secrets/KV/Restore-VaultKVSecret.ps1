function Restore-VaultKVSecret {
<#
.Synopsis
    Undeletes the data for the provided version and path in the key-value store. 

.DESCRIPTION
    Restore-VaultKVSecret undeletes the data for the provided version and path in the key-value store. 
    This restores the data, allowing it to be returned on get requests.

.EXAMPLE
    PS> Restore-VaultKVSecret -Engine dsc -SecretsPath new_path/subpath/subsubpath -Versions 1,2

    This command does not produce any output.

#>
    [CmdletBinding()]
    param(
        #Specifies a KV engine to restore secrets to.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [String] $Engine,

        #Specifies the secrets path to restore secrets to.
        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [String] $SecretsPath,

        #Specifies the versions to restored. Restored secrets will once again be returned in normal Get-VaultKVSecret calls.
        [Parameter(
            Mandatory = $true,
            Position = 2
        )]
        [Int[]] $Versions
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
    }

    process {
        $uri = $global:VAULT_ADDR

        $psobjPayload = [pscustomobject]@{
            versions = $Versions
        }

        $jsonPayload = $($psobjPayload | ConvertTo-Json -Compress)

        $irmParams = @{
            Uri    = "$uri/v1/$Engine/undelete/$SecretsPath"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Post'
            Body   = $jsonPayload
        }

        try {
            Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }
    }

    end {

    }
}