function New-VaultPolicy {
<#
.Synopsis
    Creates a new Vault policy with a specified name and policy document.

.DESCRIPTION
    New-VaultPolicy creates a new Vault policy with a specified name and at least one policy document.

.EXAMPLE
    PS> $policyDocument = @"
    >> #Denies a token from accessing the /conf_ag secret path.
    >> path "dsc/SQLAG/conf_ag/*" {
    >>   capabilities = ["deny"]
    >> }
    >> "@

    PS> New-VaultPolicy -PolicyName 'deny-sqlag-conf-ag' -PolicyDocuments $policyDocument
    
    This example does not produce any output.

.EXAMPLE
    PS> $policyDocuments = @(New-VaultPolicyDocument -PolicyPath "dsc/*" -PolicyCapabilities Create, Read, Update, Delete, List -PolicyComment "Allows a token to manage the DSC KV")
    PS> $policyDocuments += @(New-VaultPolicyDocument -PolicyPath "jenkins/*" -PolicyCapabilities Read, List -PolicyComment "Allows a token to enumerate the jenkins KV")

    PS> New-VaultPolicy -PolicyName 'dsc-jenkins-secret-consumer' -PolicyDocuments $policyDocuments

    This example demonstates using New-VaultPolicyDocument to generate two policy documents, which are then specified in the New-VaultPolicy call.
#>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium' 
    )]
    param(
        #Specifies the name of a policy to create.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [Alias('Name')]
        [String] $PolicyName,

        #Specifies one or more policy documents.
        #Policy documents can be crafted manually or generated with New-VaultPolicyDocument.
        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [Alias('Documents')]
        [String[]] $PolicyDocuments
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        if (Get-VaultPolicy -PolicyName $PolicyName -ErrorAction 'SilentlyContinue') {
            Write-Error "The specified policy '$PolicyName' already exists."
            return
        }

        $uri = $global:VAULT_ADDR

        #join all of the policy documents together as a single string with two line breaks between each document.
        $policyHash += @{ policy = $($PolicyDocuments -join "`n`n") }
        
        $policyObj = [pscustomobject] $policyHash

        $irmParams = @{
            Uri    = "$uri/v1/sys/policy/$PolicyName"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Put'
            Body   = $($policyObj | ConvertTo-Json -Compress)
        }

        if ($PSCmdlet.ShouldProcess("policy/$PolicyName",'Create Vault policy')) {
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