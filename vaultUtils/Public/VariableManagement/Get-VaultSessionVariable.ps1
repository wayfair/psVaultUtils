function Get-VaultSessionVariable {
    [CmdletBinding()]
    param()

    begin {
        Try {
            Stop-Transcript
            Write-Warning "A running Transcript was stopped to prevent writing token information to disk."
        }
        Catch {
            #Transcript was not running.
        }
    }

    process {
        Get-Variable | Where-Object Name -match "VAULT_"
    }

    end {

    }
}
