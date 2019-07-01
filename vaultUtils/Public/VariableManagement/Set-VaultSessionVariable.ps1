function Set-VaultSessionVariable {
<#
.Synopsis
    Sets various VAULT_ variables, given a vault URL, PsCredential and Login Method.

.DESCRIPTION
    Set-VaultSessionVariable configures VAULT_ADDR, VAULT_ADDR_STANDBY, VAULT_CRED, VAULT_LOGIN_METHOD and VAULT_NODES, 
    given a Vault URL, a Username/Password in PSCredential format and a Login Method. 

    VAULT_ADDR, VAULT_CRED and VAULT_LOGIN_METHOD specifically are required to 
    retrieve a Vault Token, which, in turn is required to perform most actions in Vault.

    This command does not set VAULT_TOKEN.

.EXAMPLE
    PS> $cred = Get-Credential

    PS> Set-VaultSessionVariable -VaultURL https://hvault.devcorp.wayfair.com -Credential $cred -LoginMethod LDAP -Passthru

    Name                           Value
    ----                           -----
    VAULT_ADDR                     https://active.vault.service.consul.devcorp.wayfair.com
    VAULT_ADDR_STANDBY             https://standby.vault.service.consul.devcorp.wayfair.com
    VAULT_CRED                     System.Management.Automation.PSCredential
    VAULT_LOGIN_METHOD             LDAP
    VAULT_NODES                    {devbo1chvault01.devcorp.wayfair.com, devbo1chvault02.devcorp.wayfair.com}

.EXAMPLE
    PS> Set-VaultSessionVariable -VaultURL 'vault.service.consul.devcorp.wayfair.com' -Credential $cred -LoginMethod LDAP -Passthru

    Name                           Value
    ----                           -----
    VAULT_ADDR                     https://active.vault.service.consul.devcorp.wayfair.com
    VAULT_ADDR_STANDBY             https://standby.vault.service.consul.devcorp.wayfair.com
    VAULT_CRED                     System.Management.Automation.PSCredential
    VAULT_LOGIN_METHOD             LDAP
    VAULT_NODES                    {devbo1chvault01.devcorp.wayfair.com, devbo1chvault02.devcorp.wayfair.com}

    This example demonstrates specifying a consul DNS entry. Note that 'https://' is missing from the value.
#>
    [CmdletBinding()]
    param(
        #Specifies a full URL to access Vault. Accepts a consul URL.
        [Parameter(
            Mandatory = $true
        )]
        [String] $VaultURL,

        #Specifies a credential used to authenticate to Vault. An LDAP credential can be specified as either "DOMAIN\Username" or "Username". 
        [PSCredential] $Credential,

        #Specifies a login method used to authenticate to Vault.
        [Parameter(
            Mandatory = $true
        )]
        [ValidateSet('LDAP','Userpass')]
        [String] $LoginMethod,

        #Specifies that the resulting VAULT_ variables should be displayed in the console.
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

                $dnsResult = Resolve-DnsName $url.Host -Type 'Cname' -ErrorAction 'SilentlyContinue' | 
                    Select-Object -ExpandProperty 'NameHost'

                $activeUrl  = 'https://active.'  + $dnsResult
                $standbyUrl = 'https://standby.' + $dnsResult
            }
            else {
                $dnsResult = Resolve-DnsName $VaultURL -Type 'Cname' -ErrorAction 'SilentlyContinue' | 
                    Select-Object -ExpandProperty 'NameHost'

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
                Resolve-DnsName -ErrorAction 'SilentlyContinue' |
                    Where-Object QueryType -eq 'A' | 
                        Select-Object -ExpandProperty Name

        $global:VAULT_NODES += $([System.Uri]($standbyUrl)) |
            Select-Object -ExpandProperty 'Host' | 
                Resolve-DnsName -ErrorAction 'SilentlyContinue' |
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