function Get-VaultStatus {
    [CmdletBinding()]
    param(
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
                Write-Warning "All Vault instances are sealed."
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