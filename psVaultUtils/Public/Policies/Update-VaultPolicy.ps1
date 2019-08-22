function Update-VaultPolicy {
    <#
    .Synopsis
        Updates/Overwrites the policy documents of an existing Vault policy.
    
    .DESCRIPTION
        Update-VaultPolicy updats/overwrites an existing Vault policy.

        This function overwrites the existing policy documents with policy documents specified at runtime. 
        This is to say, the function is destructive, not additive.
    
    .EXAMPLE
        PS> Get-VaultPolicy 'test-policy' -JustData | Select-Object -ExpandProperty rules
        #Allows a token to manage the DSC KV
        path "dsc/*" {
          capabilities = ["create", "read", "update", "delete", "list"]
        }

        #Allows a token to enumerate the jenkins KV
        path "jenkins/*" {
          capabilities = ["read", "list"]
        }

        PS> $policyDoc = New-VaultPolicyDocument -PolicyPath "auth/*" -PolicyCapabilities Read,List -PolicyComment "This policy overwrote the existing policies."
    
        PS> Update-VaultPolicy -PolicyName 'test-policy' -Policies $policyDoc
        
        PS> Get-VaultPolicy 'test-policy' -JustData | Select-Object -ExpandProperty rules

        #This policy overwrote the existing policies.
        path "auth/*" {
          capabilities = ["read", "list"]
        }


        This example demonstrates the desctructive nature of updating a policy. Existing policies documents are overwritten by newly-specified policy documents.
    #>
        [CmdletBinding(
            SupportsShouldProcess = $true,
            ConfirmImpact = 'High'
        )]
        param(
            #Specifies the name of a policy to create.
            [Parameter(
                Mandatory = $true,
                Position = 0
            )]
            [Alias('Name')]
            [String] $PolicyName,
    
            #Specifies one or more policies.
            #Policies can be crafted manually or generated with New-VaultPolicyDocument.
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
            $uri = $global:VAULT_ADDR
    
            #join all of the policies together as a single string with two line breaks between each policy.
            $policyHash += @{ policy = $($PolicyDocuments -join "`n`n") }
            
            $policyObj = [pscustomobject] $policyHash
    
            $irmParams = @{
                Uri    = "$uri/v1/sys/policy/$PolicyName"
                Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
                Method = 'Put'
                Body   = $($policyObj | ConvertTo-Json -Compress)
            }
    
            if ($PSCmdlet.ShouldProcess("$PolicyName",'Update Vault Policy')) {
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