function Set-VaultKVEngine {
<#
.Synopsis
    Modifies the CAS Required and/or Max Versions attributes of a KV Engine.

.DESCRIPTION
    Set-VaultKVEngine can be used to update the Max Versions or CAS Required attributes of a KV Engine.
    These fields determine the maximum number of versions a given secret can contain, 
    and whether or not the CheckAndSet (CAS) flag needs to be specified when writing new KV secrets to the KV engine.

.EXAMPLE
    PS> Set-VaultKVEngine -Engine test-kv -MaxVersions 5 -CheckAndSetRequired:$false

    Changes the max_versions of the 'test-kv' engine to 5, and sets cas_required to false.

    This command produces no output.

.EXAMPLE
    PS> Set-VaultKVEngine -Engine test-kv -CheckAndSetRequired:$true

    Sets cas_required to true, and sets the max_versions to the default value of 10.

    This command produces no output.
#>
    [CmdletBinding()]
    param(
        #Specifies a KV Engine to modify the properties of.
        [String] $Engine,

        #Specifies the max_versions a KV engine should be configured to accept.
        [Int] $MaxVersions = 10,

        #Specifies, as a boolean, whether or not cas_required should be configured on the KV engine.
        [Alias('CASRequired')]
        [Bool] $CheckAndSetRequired
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
    }

    process {
        $uri = $global:VAULT_ADDR

        if ($CheckAndSetRequired) {
            $cas = 'true'
        }
        else {
            $cas = 'false'
        }

        $jsonPayload = @"
{
    "max_versions": $MaxVersions,
    "cas_required": $cas
}      
"@

        $irmParams = @{
            Uri    = "$uri/v1/$Engine/config"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
            Method = 'Post'
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