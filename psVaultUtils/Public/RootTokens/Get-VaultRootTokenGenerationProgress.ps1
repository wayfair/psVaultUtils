function Get-VaultRootTokenGenerationProgress {
<#
.Synopsis
    Reads the configuration and progress of the current root generation attempt.

.DESCRIPTION
    Get-VaultRootTokenGenerationProgress reads the configuration and progress of the current root token generation attempt.

    If a root generation is started, progress is how many unseal keys have been provided for this generation attempt, where required must be reached to complete. 
    The nonce for the current attempt and whether the attempt is complete is also displayed. 
    If a PGP key is being used to encrypt the final root token, its fingerprint will be returned. 
    
    Note that if an OTP is being used to encode the final root token, it will never be returned.

.EXAMPLE
    PS> Get-VaultRootTokenGenerationProgress

    nonce              :
    started            : False
    progress           : 0
    required           : 2
    complete           : False
    encoded_token      :
    encoded_root_token :
    pgp_fingerprint    :
    otp                :
    otp_length         : 26

.EXAMPLE 
    PS> Get-VaultRootTokenGenerationProgress

    nonce              : 01a0a634-76b6-f6bc-a66d-49f2fbda027a
    started            : True
    progress           : 1
    required           : 2
    complete           : False
    encoded_token      :
    encoded_root_token :
    pgp_fingerprint    :
    otp                :
    otp_length         : 26

#>
    [CmdletBinding()]
    param(
        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 0
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject'
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/generate-root/attempt"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Get'
        }

        try {
            $result = Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }

        $formatParams = @{
            InputObject = $result
            JustData    = $false
            OutputType  = $OutputType
        }

        Format-VaultOutput @formatParams
    }

    end {

    }
}