function Get-VaultStatus {
<#
.Synopsis
    Returns the status of Vault.

.DESCRIPTION
    Get-VaultStatus returns information about the status of a Vault Cluster, 
    chosen by the value of $global:VAULT_ADDR.

.EXAMPLE
    PS> Get-Vaultstatus

    seal_type       : shamir
    initialized     : True
    sealed          : False
    total_shares    : 5
    threshold       : 3
    version         : 1.1.2
    cluster_name    : vault-cluster-47802c8f
    cluster_id      : 9708a39d-dd9c-017f-333a-5551e83d9be7
    cluster_leader  : https://DEVVAULT02.domain.com:443
    server_time_utc : 7/1/2019 4:13:50 PM +00:00
    ha_enabled      : True

.EXAMPLE
    PS> Get-Vaultstatus -OutputType Json
    {
        "seal_type":  "shamir",
        "initialized":  true,
        "sealed":  false,
        "total_shares":  5,
        "threshold":  3,
        "version":  "1.1.2",
        "cluster_name":  "vault-cluster-47802c8f",
        "cluster_id":  "9708a39d-dd9c-017f-333a-5551e83d9be7",
        "cluster_leader":  "https://DEVVAULT02.domain.com:443",
        "server_time_utc":  "\/Date(1561997735000)\/",
        "ha_enabled":  true
    }
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
        Test-VaultSessionVariable -CheckFor 'Address'
    }

    process {

        $address = $global:VAULT_ADDR
        
        try {
            $leaderResponse = Invoke-RestMethod -Uri "$address/v1/sys/leader" -ErrorAction Stop
        }
        catch {
            if ($_.ErrorDetails.Message -match "Vault is sealed") {
                Write-Warning "Vault is sealed."
            }

            if ($_.Exception -match "The remote name could not be resolved") {
                Write-Warning "Vault is sealed."
            }
        }

        try {
            $healthResponse = Invoke-RestMethod -Uri "$address/v1/sys/health?standbyok=true" 
        }
        Catch {

        }

        try {
            $sealResponse = Invoke-RestMethod -Uri "$address/v1/sys/seal-status"
        }
        catch {

        }

        if ($healthResponse.server_time_utc) {
            $serverTimeUTC = $([DateTimeOffSet]::FromUnixTimeSeconds($healthResponse.server_time_utc))
        }

        $result = [pscustomobject] @{
            seal_type       = $sealResponse.type
            initialized     = $sealResponse.initialized
            sealed          = $sealResponse.sealed
            total_shares    = $sealResponse.n
            threshold       = $sealResponse.t
            version         = $sealResponse.Version 
            cluster_name    = $healthResponse.cluster_name
            cluster_id      = $healthResponse.cluster_id
            cluster_leader  = $leaderResponse.leader_address
            server_time_utc = $serverTimeUTC
            ha_enabled      = $leaderResponse.ha_enabled
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