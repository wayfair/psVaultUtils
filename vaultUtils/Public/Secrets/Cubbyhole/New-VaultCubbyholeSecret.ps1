function New-VaultCubbyholeSecret {
<#
.Synopsis
    Stores secret data at a specified location in the cubbyhole.

.DESCRIPTION
    New-VaultCubbyholeSecret stores secret data at a specified location in the cubbyhole.

    If a path that already exists is specified, existing data ia overwritten.

    Unlike New-VaultKVSecret, this command does not produce any outout.

.EXAMPLE
    PS> New-VaultCubbyholeSecret -SecretsPath new/path/foo -Secrets @{'foo'='bar'}

    This command does not produce any output.

#>
    [CmdletBinding()]
    param(
        #Specifies the cubbyhole secret path to write a secret to.
        [Parameter(
            Position = 0
        )]
        [String] $SecretsPath,

        #Specifies a hashtable of one or more KV pairs, of which the values are "secrets".
        [Parameter(
            Position = 1
        )]
        [Hashtable] $Secrets
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        $secretString = @()
        foreach ($s in $Secrets.GetEnumerator()) {
            $secretString += "`"$($s.Name)`": `"$($s.Value)`""
        }

        $jsonPayload = @"
{
    $($secretString -join ", ")
}
"@

        $irmParams = @{
            Uri    = "$uri/v1/cubbyhole/$SecretsPath"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Post'
            Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
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

Set-Alias -Name 'Update-VaultCubbyholeSecret' -Value 'New-VaultCubbyholeSecret.ps1'