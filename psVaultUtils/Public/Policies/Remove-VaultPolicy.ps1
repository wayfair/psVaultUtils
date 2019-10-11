function Remove-VaultPolicy {
<#
.Synopsis
    Deletes a specified policy from Vault.

.DESCRIPTION
    Remove-VaultPolicy deletes a specified policy from Vault. 
    This will immediately affect all users associated with the policy.

.EXAMPLE
    PS> Remove-VaultPolicy dsc-secret-consumer

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "Delete Vault Policy" on target "dsc-secret-consumer".
    [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): y


    This command does not produce any output.
    
#>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param(
        #Specifies the name of a policy to remove.
        [Parameter(
            Position = 0
        )]
        [String] $PolicyName
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/policy/$PolicyName"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Delete'
        }

        if ($PSCmdlet.ShouldProcess("$PolicyName",'Delete Vault Policy')) {
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