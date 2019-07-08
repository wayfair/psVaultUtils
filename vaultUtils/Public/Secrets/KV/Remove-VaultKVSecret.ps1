function Remove-VaultKVSecret {
<#
.Synopsis
    Issues a soft delete of the specified versions of the secret. 
    If Force is specified, issues a hard delete of the specified versions of the secret instead. 

.DESCRIPTION
    Remove-VaultKVSecret issues a soft delete of the specified versions of the secret. 
    This marks the versions as deleted and will stop them from being returned from reads, but the underlying data will not be removed. 
    A delete can be undone using Restore-VaultKVSecret.

    If the Force parameter is specified, the data is destroyed isntead. This makes the data unrecoverable.

.EXAMPLE
    PS> Remove-VaultKVSecret -Engine dsc -SecretsPath new_path/subpath/subsubpath -Versions 1,2

    This command does not produce any output.

.EXAMPLE
    PS> Remove-VaultKVSecret -Engine dsc -SecretsPath new_path/subpath/subsubpath -Versions 1,2 -Force

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "Destory Vault Secret(s)" on target "new_path/subpath/subsubpath".
    [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): y

    The Force flag destroys the data, making it unrecoverable.

    This command does not produce any output.

#>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        #Specifies a KV engine to delete secrets from.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [String] $Engine,

        #Specifies the secrets path to delete secrets from.
        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [String] $SecretsPath,

        #Specifies the versions to delete. Deleted version will not be deleted, but they will no longer be returned in normal Get-VaultKVSecret calls.
        [Parameter(
            Mandatory = $true,
            Position = 2
        )]
        [Int[]] $Versions,

        #Specifies the data will be destroyed. Unlike deleted secrets, secrets which are destoryed cannot be recovered using Restore-VaultKVSecret.
        [Parameter(
            Position = 3
        )]
        [Switch] $Force
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
    }

    process {
        $uri = $global:VAULT_ADDR

        if ($Force) {
            $fullUri = "$uri/v1/$Engine/destroy/$SecretsPath"
        }
        else {
            $fullUri = "$uri/v1/$Engine/delete/$SecretsPath"
        }

        $psobjPayload = [pscustomobject]@{
            versions = $Versions
        }

        $jsonPayload = $($psobjPayload | ConvertTo-Json -Compress)

        $irmParams = @{
            Uri    = $fullUri
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Post'
            Body   = $jsonPayload
        }

        if ($Force) {
            if ($PSCmdlet.ShouldProcess("$SecretsPath",'Destory Vault Secret(s)')) {
                try {
                    Invoke-RestMethod @irmParams
                }
                catch {
                    throw
                }
            }
        }
        else {
            try {
                Invoke-RestMethod @irmParams
            }
            catch {
                throw
            }
        }
    }

    end {

    }
}