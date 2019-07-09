function Get-VaultRekeyVerificationProgress {
<#
.Synopsis
    Gets the configuration and progress of the current rekey verification attempt.

.DESCRIPTION
    Get-VaultRekeyProgress gets the configuration and current progress of the current rekey verification attempt.
    
.EXAMPLE
    PS> Get-VaultRekeyVerificationProgress

    nonce    :
    started  : False
    t        : 5
    n        : 10
    progress : 0

.EXAMPLE 
    PS> Get-VaultRekeyVerificationProgress
    Invoke-RestMethod : {"errors":["no rekey configuration found"]}
    At C:\Program Files\WindowsPowerShell\Modules\vaultUtils\0.0.1\Public\Server-Key\Get-VaultRekeyVerificationProgress.ps1:46 char:23
    +             $result = Invoke-RestMethod @irmParams
    +                       ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        + CategoryInfo          : InvalidOperation: (System.Net.HttpWebRequest:HttpWebRequest) [Invoke-RestMethod], WebException
        + FullyQualifiedErrorId : WebCmdletWebResponseException,Microsoft.PowerShell.Commands.InvokeRestMethodCommand

    This example demonstrates that an error is thrown if there is no rekey in progress. 
#>
    [CmdletBinding()]
    param(
        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 0
        )]
        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject'
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/rekey/verify"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Get'
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