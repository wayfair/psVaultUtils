function Unprotect-VaultRootToken {
<#
.Synopsis
    Decodes an encoded root token, given the encoded root token and an OTP.

.DESCRIPTION
    Unprotect-VaultRootToken decodes an encoded root token using a one-time-password. 
    The OTP is delivered when root token generation is started. 

.EXAMPLE
    PS> Unprotect-VaultRootToken -Otp iLXe0yoRia3OXHw7yv7UN0Jouk -EncodedRootToken GmIJPXUfASICCUUEFCA2YQlGRTMfcxssAiE

    request_id     : 9bd40f22-770d-684c-36e6-439c762030f9
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{accessor=AYzIvRGOhU97OFMMLAR3fgmB; creation_time=1562359972; creation_ttl=0; display_name=root;
                    entity_id=; expire_time=; explicit_max_ttl=0; id=s.QXEfnpkhvKLhAVp0rfQCQCwJ; meta=; num_uses=0;
                    orphan=True; path=auth/token/root; policies=System.Object[]; ttl=0; type=service}
    wrap_info      :
    warnings       :
    auth           :

#>
    [CmdletBinding()]
    param(
        #Specifies an encoded root token.
        [String] $EncodedRootToken,

        [String] $Otp,

        #Specifies how output information should be displayed in the console. Available options are JSON, PSObject or Hashtable.
        [Parameter(
            Position = 1
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject'
    )

    begin {

    }

    process {
        #Encoded Root Tokens are 35 bytes which cannot be converted to base64 without an appended equal sign for padding.
        $eTokenBase64 = [System.Convert]::FromBase64String($EncodedRootToken + "=")

        $otpLength = $Otp.Length

        for ($i = 0; $i -lt $otpLength; $i++) {
            $otpByte    = [Byte] $otp[$i]
            $eTokenByte = [Byte] $eTokenBase64[$i]

            $result += $([char] $($otpByte -bxor $eTokenByte))
        }

        Get-VaultToken -Token $result -OutputType $OutputType
    }

    end {

    }
}

Set-Alias -Name 'Decode-VaultRootToken' -Value 'Unprotect-VaultRootToken'