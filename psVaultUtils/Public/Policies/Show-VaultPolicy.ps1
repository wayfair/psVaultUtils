function Show-VaultPolicy {
<#
.Synopsis
    Lists all configured policies in Vault.

.DESCRIPTION
    Show-VaultPolicy lists all configured policies in Vault.

.EXAMPLE
    PS> Show-VaultPolicy

    keys           : {default, dsc-secret-consumer, jenkinsc01-secret-consumer, jenkinsc02-secret-consumer...}
    policies       : {default, dsc-secret-consumer, jenkinsc01-secret-consumer, jenkinsc02-secret-consumer...}
    request_id     : b871c03e-9760-6774-5c83-4e274dd2cfee
    lease_id       :
    renewable      : False
    lease_duration : 0
    data           : @{keys=System.Object[]; policies=System.Object[]}
    wrap_info      :
    warnings       :
    auth           :

.EXAMPLE
    PS> Show-VaultPolicy -JustPolicies | Select-Object -ExpandProperty policies
    
    default
    dsc-secret-consumer
    jenkins-secret-consumer
    log-rotation
    operator
    root
#>
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject',

        [Switch] $JustPolicies
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/policy"
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
            DataType    = 'policy_data'
            JustData    = $JustPolicies.IsPresent
            OutputType  = $OutputType
        }

        Format-VaultOutput @formatParams
    }

    end {

    }
}

Set-Alias -Name 'List-VaultPolicy' -Value 'Show-VaultPolicy'