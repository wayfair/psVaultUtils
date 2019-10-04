function Get-VaultKeyStatus {
<#
.Synopsis
    Returns information about the current encryption key used by Vault.

.DESCRIPTION
    Get-VaultKeyStatus returns information about the current encryption key used by Vault.

.EXAMPLE
    PS> Get-VaultKeyStatus

    term           : 1
    install_time   : 2019-06-12T18:14:41.709045-04:00
    request_id     : 06b93991-2b0b-31d0-bab5-19f12c1b0042
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{install_time=2019-06-12T18:14:41.709045-04:00; term=1}
    wrap_info      :
    warnings       :
    auth           :

#>
    [CmdletBinding()]
    param(
        #Specifies how output information should be displayed in the console. Available options are JSON, PSObject or Hashtable.
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
            Uri    = "$uri/v1/sys/key-status"
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