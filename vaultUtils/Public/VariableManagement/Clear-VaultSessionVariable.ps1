function Clear-VaultSessionVariable {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true
        )]
        $Variables
    )

    begin {

    }

    process {
        if ($Variables) {
            $Variables | Clear-Variable -Scope 'Global'
        }
        else {
            Get-Variable | Where-Object Name -match "VAULT_" | Clear-Variable -Scope 'Global'
        }
    }

    end {

    }
}
    