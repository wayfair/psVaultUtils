function Get-VaultMetric {
<#
.Synopsis
    Retrieves telemetry metrics from Vault.

.DESCRIPTION
    Get-VaultMetric is used to retrieve telemetry metrics from Vault. Optional parameters can be used to pull specific metrics like Gauge or Sample information.

.EXAMPLE
    PS> Get-VaultMetric -OutputType PSObject

    Timestamp : 2019-07-03 14:54:50 +0000 UTC
    Gauges    : {@{Name=vault.expire.num_leases; Value=39; Labels=}, @{Name=vault.runtime.alloc_bytes; Value=8229192; Labels=},
                @{Name=vault.runtime.free_count; Value=230590020; Labels=}, @{Name=vault.runtime.heap_objects; Value=47648;
                Labels=}...}
    Points    : {}
    Counters  : {}
    Samples   : {@{Name=vault.barrier.put; Count=1; Rate=1.5001099586486817; Sum=15.001099586486816; Min=15.001099586486816;
                Max=15.001099586486816; Mean=15.001099586486816; Stddev=0; Labels=}, @{Name=vault.consul.put; Count=1;
                Rate=1.5001099586486817; Sum=15.001099586486816; Min=15.001099586486816; Max=15.001099586486816;
                Mean=15.001099586486816; Stddev=0; Labels=}}

.EXAMPLE
    PS> Get-VaultMetric -OutputType PSObject -JustGauges

    Name                                 Value Labels
    ----                                 ----- ------
    vault.expire.num_leases                 39
    vault.runtime.alloc_bytes          9206712
    vault.runtime.free_count         230591170
    vault.runtime.heap_objects           58076
    vault.runtime.malloc_count       230649230
    vault.runtime.num_goroutines            33
    vault.runtime.sys_bytes           38435064
    vault.runtime.total_gc_pause_ns 1528267500
    vault.runtime.total_gc_runs           9389
#>
    [CmdletBinding(
        DefaultParameterSetName = 'All'
    )]
    param(
        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 0
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just gauges information should be displayed in the console.
        [Parameter(
            ParameterSetName = 'Gauges',
            Position = 1
        )]
        [Switch] $JustGauges,

        #Specifies whether or not just gauges information should be displayed in the console.
        [Parameter(
            ParameterSetName = 'Points',
            Position = 2
        )]
        [Switch] $JustPoints,

        [Parameter(
            ParameterSetName = 'Counters',
            Position = 3
        )]
        [Switch] $JustCounters,

        [Parameter(
            ParameterSetName = 'Samples',
            Position = 4
        )]
        [Switch] $JustSamples
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/metrics"
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
            OutputType  = $OutputType
        }

        if ($PSCmdlet.ParameterSetName -ne 'All') {
            $formatParams += @{ DataType = "metrics_$($PSCmdlet.ParameterSetName)".ToLower() }
            $formatParams += @{ JustData = $true }
        }

        Format-VaultOutput @formatParams
    }

    end {

    }
}