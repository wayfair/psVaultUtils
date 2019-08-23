function Remove-VaultTokenRole {
<#
.Synopsis
    Deletes a specified token role.
    
.DESCRIPTION
    Remove-VaultTokenRole deletes a specified token role from Vault.

.EXAMPLE
    PS> Remove-VaultTokenRole log-rotate

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "Remove Token Role" on target "log-rotate".
    [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): y


    This command does not produce any output.
#>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        #Specifies the role whose configuration should be retrieved.
        [Parameter(
            Position = 0
        )]
        [String] $RoleName,

        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 1
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the token roles should be displayed in the console.
        [Parameter(
            Position = 2
        )]
        [Switch] $JustData
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/auth/token/roles/$RoleName"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Delete'
        }

        if ($PSCmdlet.ShouldProcess("$RoleName",'Delete Token Role')) {
            try {
                Invoke-RestMethod @irmParams
            }
            catch {
                throw
            }
        }
    }

    end {

    }
}