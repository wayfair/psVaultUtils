function Start-VaultRekey {
<#
.Synopsis
    Initializes a new rekey attempt. 

.DESCRIPTION
    Start-VaultRekey initializes a new rekey attempt. 
    Only a single rekey attempt can take place at a time, and changing the parameters of a rekey requires canceling 
    and starting a new rekey, which will also provide a new nonce.

.EXAMPLE
    PS> Start-VaultRekey -SecretShares 10 -SecretThreshold 5 -RequireVerification

    nonce                 : c5cb3972-9e52-30eb-e396-32ed62099fb7
    started               : True
    t                     : 5
    n                     : 10
    progress              : 0
    required              : 3
    pgp_fingerprints      :
    backup                : False
    verification_required : True
    
#>
    [CmdletBinding()]
    param(
        #Specifies the number of shares to split the master key into.
        [Parameter(
            Position = 0
        )]
        [Int] $SecretShares = 5,

        #Specifies the number of shares that are required to reconstruct the master key. Must be less than or equal to SecretShares.
        [Parameter(
            Position = 1
        )]
        [Int] $SecretThreshold = 3,

        #Specifies an array of PGP public keys used to encrypt the output unseal keys. Ordering is preserved. 
        #The keys must be base64-encoded from their original binary representation. 
        #The size of this array must be the same as SecretShares.
        [Parameter(
            Position = 2
        )]
        [String[]] $PGPKeys,

        #Specifies if using PGP-encrypted keys, whether Vault should also store a plaintext backup of the PGP-encrypted keys 
        #at core/unseal-keys-backup in the physical storage backend. 
        #These can then be retrieved and removed via the sys/rekey/backup endpoint.
        [Parameter(
            Position = 3
        )]
        [Switch] $Backup,

        #Specifies that verification functionality should be enabled. 
        #When verification is turned on, after successful authorization with the current unseal keys, the new unseal keys are returned,
        #but the master key is not actually rotated. 
        #The new keys must be provided to authorize the actual rotation of the master key. 
        #This ensures that the new keys have been successfully saved and protects against a risk of the keys being lost after rotation but before they can be persisted. 
        #This can be used with without PGPKeys, and when used with it, it allows ensuring that the returned keys can be 
        #successfully decrypted before committing to the new shares, which the backup functionality does not provide.
        [Parameter(
            Position = 4
        )]
        [Switch] $RequireVerification
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
    }

    process {
        #region Parameter Validation

        if ($SecretThreshold -gt $SecretShares) {
            Write-Error "The Secret Threshold must be less than or equal the number of Secret Shares."
            return
        }

        if ($Backup -and (-not $PGPKeys)) {
            Write-Error "Cannot request a backup of the new keys without providing PGP keys for encryption."
            return
        }

        if ($PGPKeys) {
            if (($PGPKeys | Measure-Object).Count -ne $SecretShares) {
                Write-Error "The count of supplied PGP Keys must be equal to the number of Secret Shares."
                return
            }

            foreach ($pKey in $PGPKeys) {
                if ($pKey -notmatch "^[a-zA-Z0-9\+/]*={0,2}$") {
                    Write-Error "All specified PGP Keys must be Base64-encoded strings. The following PGP Key is invalid: '$pKey'"
                    return
                }
            }
        }

        #endregion

        #region Build JSON Payload

        $psobjPayload = @{
            secret_shares        = $SecretShares
            secret_threshold     = $SecretThreshold
            backup               = $Backup.IsPresent
            require_verification = $RequireVerification.IsPresent
        }

        if ($PGPKeys) {
            $psobjPayload += @{ pgp_keys = $PGPKeys }
        }

        $jsonPayload = $([pscustomobject] $psobjPayload) | ConvertTo-Json -Compress

        #endregion

        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/rekey/init"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Put'
            Body   = $jsonPayload
        }

        try {
            $result = Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }

        if ($OutputType -eq "Json") {
            $result | ConvertTo-Json
        }
        else {
            $result
        }
    }

    end {

    }
}