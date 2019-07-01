function Set-VaultSessionVariable {
    [CmdletBinding()]
    param(
        #Specifies the full URL to access Vault.
        [Parameter(
            Mandatory = $true
        )]
        [String] $VaultURL,

        [PSCredential] $Credential,


        [Parameter(
            Mandatory = $true
        )]
        [ValidateSet('LDAP','Userpass')]
        [String] $LoginMethod,

        [Switch] $Passthru
    )

    begin {
        
    }

    process {

        #region Handle Credential // Login Method

        $global:VAULT_LOGIN_METHOD = $LoginMethod

        if ($Credential) {
            $global:VAULT_CRED = $Credential
            Write-Verbose 'Cred specified'
        }
        elseif ((-not $Credential) -and (-not $global:VAULT_CRED)) {
            [PSCredential] $Credential = Get-Credential
            $global:VAULT_CRED = $Credential

            Write-verbose "no cred and no global cred"
        }

        #endregion

        #region Intelligently Handle VaultURL

        if ($VaultURL -match "consul") {
            if (($VaultURL -match "https://") -or ($VaultURL -match "http://")) {
                $url = [System.Uri]($VaultURL)

                $activeUrl  = 'https://active.'  + $url.Host
                $standbyUrl = 'https://standby.' + $url.Host 
            }
            else {
                $activeUrl  = 'https://active.'  + $VaultURL
                $standbyUrl = 'https://standby.' + $VaultURL 
            }
        }
        else {
            if (($VaultURL -match "https://") -or ($VaultURL -match "http://")) {
                $url = [System.Uri]($VaultURL)

                $dnsResult = Resolve-DnsName $url.Host -Type 'Cname' | Select-Object -ExpandProperty 'NameHost'

                $activeUrl  = 'https://active.'  + $dnsResult
                $standbyUrl = 'https://standby.' + $dnsResult
            }
            else {
                $dnsResult = Resolve-DnsName $VaultURL -Type 'Cname' | Select-Object -ExpandProperty 'NameHost'

                $activeUrl  = 'https://active.'  + $dnsResult
                $standbyUrl = 'https://standby.' + $dnsResult
            }
        }

        $global:VAULT_ADDR         = $activeUrl
        $global:VAULT_ADDR_STANDBY = $standbyUrl

        #endregion

        #region Get Underlying Vault hosts

        $global:VAULT_NODES = @()

        $global:VAULT_NODES += $([System.Uri]($activeUrl)) | 
            Select-Object -ExpandProperty 'Host' | 
                Resolve-DnsName |
                    Where-Object QueryType -eq 'A' | 
                        Select-Object -ExpandProperty Name

        $global:VAULT_NODES += $([System.Uri]($standbyUrl)) |
            Select-Object -ExpandProperty 'Host' | 
                Resolve-DnsName |
                    Where-Object QueryType -eq 'A' | 
                        Select-Object -ExpandProperty Name

        #endregion

        if ($Passthru) {
            Get-VaultSessionVariable
        }
    }

    end {

    }
}