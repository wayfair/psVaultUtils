function New-VaultKVSecret {
<#
.Synopsis
    Creates a new secret or series of secrets in Vault, given a KV Engine and a secrets path.

.DESCRIPTION
    New-VaultKVSecret is capable of creating a new secret or series of secrets in Vault,
    given a KV secret engine and a relative path to the secret(s).

.EXAMPLE
    PS> New-VaultKVSecret -Engine dsc -SecretsPath sql_ag/pwst_ag -Secrets @{ 'sa_sql_dbe_pwst'='Pa$$w.rd' }

    request_id     : 9e3a7c00-dbb6-1f8c-179f-8defcaed2df5
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{created_time=2019-07-01T15:56:15.8780863Z; deletion_time=; destroyed=False; version=1}
    wrap_info      :
    warnings       :
    auth           :

    Because no OutputType was specified, the metadata about the secret is returned in full, as a PSObject. 
    Note that the actual secret information is not returned to the console.

.EXAMPLE
    PS> New-VaultKVSecret -Engine dsc -SecretsPath new_path/subpath/subsubpath -Secrets @{ 'Username'='password' }

    request_id     : 1a8a91cc-09e6-bdaf-f9e2-ae987349dcab
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{created_time=2019-07-01T15:57:47.3836696Z; deletion_time=; destroyed=False; version=1}
    wrap_info      :
    warnings       :
    auth           :


    This example demonstrates creating a secret at an entirely new path, which is completely acceptable.

.EXAMPLE
    PS> $secrets = @{ 'Username2'='password2'; 'Username3'='Password3' }

    PS> New-VaultKVSecret -Engine dsc -SecretsPath new_path/subpath/subsubpath -Secrets $secrets -CheckAndSet 1

    request_id     : 202f4e4f-5b33-5408-f74c-e75f6130dcdf                                                    
    lease_id       :                                                                                         
    renewable      : False                                                                                   
    lease_duration : 0                                                                                       
    data           : @{created_time=2019-07-01T16:02:14.4083795Z; deletion_time=; destroyed=False; version=2}
    wrap_info      :                                                                                         
    warnings       :                                                                                         
    auth           :                                                                                         

    This example demonstrates a scenario where multiple KV pairs are added to 'dsc' engine at path 'new_path/subpath/subsubpath'
    CheckAndSet needs to be specified as 1 because a version of KV information already exists at this path.
#>
    [CmdletBinding()]
    param(
        #Specifies a KV engine to write secrets to.
        [String] $Engine,

        #Specifies the secrets path to write a secret to.
        [String] $SecretsPath,

        #Specifies a hashtable of one or more KV pairs, of which the values are "secrets"
        [Hashtable] $Secrets,

        #Specifies the CheckAndSet (CAS) version the secret should be written to. This generally needs to be incremented when updating a secret.
        [ValidateScript({ $_ -gt 0 })]
        [Int] $CheckAndSet,

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
        $uri = $global:VAULT_ADDR

        $secretString = @()
        foreach ($s in $Secrets.GetEnumerator()) {
            $secretString += "`"$($s.Name)`": `"$($s.Value)`""
        }

        $jsonPayload = @"
{
    "options": {
        "cas": $CheckAndSet
    },
    "data": {
        $($secretString -join ", ")
    }
}      
"@

        $irmParams = @{
            Uri    = "$uri/v1/$Engine/data/$SecretsPath"
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
                    if ($MetaData) {
                        $result.data | ConvertTo-Json
                    }
                    else {
                        $result.data.data | ConvertTo-Json
                    }
                }
                else {
                    $result | ConvertTo-Json
                }
            }

            'PSObject' {
                if ($JustData) {
                    if ($MetaData) {
                        $result.data
                    }
                    else {
                        $result.data.data
                    }
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