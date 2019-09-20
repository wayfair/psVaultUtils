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

    PS> Set-VaultSessionVariable -VaultURL https://hvault.domain.com -Credential $cred -LoginMethod LDAP -Passthru

    Name                           Value
    ----                           -----
    VAULT_ADDR                     https://active.vault.service.consul.domain.com
    VAULT_ADDR_STANDBY             https://standby.vault.service.consul.domain.com
    VAULT_CRED                     System.Management.Automation.PSCredential
    VAULT_LOGIN_METHOD             LDAP
    VAULT_NODES                    {devvault01.domain.com, devvault02.domain.com}

.EXAMPLE
    PS> Set-VaultSessionVariable -VaultURL 'vault.service.consul.domain.com' -Credential $cred -LoginMethod LDAP -Passthru

    Name                           Value
    ----                           -----
    VAULT_ADDR                     https://active.vault.service.consul.domain.com
    VAULT_ADDR_STANDBY             https://standby.vault.service.consul.domain.com
    VAULT_CRED                     System.Management.Automation.PSCredential
    VAULT_LOGIN_METHOD             LDAP
    VAULT_NODES                    {devvault01.domain.com, devvault02.domain.com}

    This example demonstrates specifying a consul DNS entry. Note that 'https://' is missing from the value.
#>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param(
        #Specifies a full URL to access Vault. Accepts a consul URL.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [String] $VaultURL,

        #Specifies a credential used to authenticate to Vault. An LDAP credential can be specified as either "DOMAIN\Username" or "Username".
        [Parameter(
            Position = 1
        )] 
        [PSCredential] $Credential,

        #Specifies a login method used to authenticate to Vault.
        #Currently the only supported login method is LDAP.
        [Parameter(
            Mandatory = $true,
            Position = 2
        )]
        [ValidateSet('LDAP')]
        [String] $LoginMethod,

        #Specifies that the resulting VAULT_ variables should be displayed in the console.
        [Parameter(
            Position = 3
        )]
        [Switch] $Passthru
    )

    begin {
        
    }

    process {

        #region Handle Credential // Login Method

        if ($PSCmdlet.ShouldProcess('$global:VAULT_LOGIN_METHOD','Assign Vault login method')) {
            $global:VAULT_LOGIN_METHOD = $LoginMethod
        }

        if ($PSCmdlet.ShouldProcess('$global:VAULT_CRED','Assign Vault credential')) {
            if ($Credential) {
                $global:VAULT_CRED = $Credential
            }
            elseif ((-not $Credential) -and (-not $global:VAULT_CRED)) {
                [PSCredential] $Credential = Get-Credential -Message "Please specify credentials to log into Hashicorp Vault:"
                $global:VAULT_CRED = $Credential
            }
        }

        #endregion

        #region Intelligently Handle VaultURL

        if ($PSCmdlet.ShouldProcess('$global:VAULT_ADDR, $global:VAULT_ADDR_STANDBY','Assign Vault addresses')) {
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
        }

        #endregion

        #region Get Underlying Vault hosts

        if ($PSCmdlet.ShouldProcess('$global:VAULT_NODES','Assign Vault nodes')) {
            $global:VAULT_NODES = @()

            $global:VAULT_NODES += $([System.Uri]($activeUrl)) | 
                Select-Object -ExpandProperty 'Host' | 
                    Resolve-DnsName -ErrorAction 'SilentlyContinue' |
                        Where-Object QueryType -eq 'A' | 
                            Select-Object -ExpandProperty 'Name'

            $global:VAULT_NODES += $([System.Uri]($standbyUrl)) |
                Select-Object -ExpandProperty 'Host' | 
                    Resolve-DnsName -ErrorAction 'SilentlyContinue' |
                        Where-Object QueryType -eq 'A' | 
                            Select-Object -ExpandProperty 'Name'

            if ($Passthru) {
                Get-VaultSessionVariable
            }
        }

        #endregion
    }

    end {

    }
}