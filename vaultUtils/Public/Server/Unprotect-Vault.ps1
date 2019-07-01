function Unprotect-Vault {
    [CmdletBinding()]
    param(
        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject'
    )

    DynamicParam {
        # Set the dynamic parameters' name.
        $ParameterName = 'VaultNode'
    
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    
        # Create and set the parameters' attributes. You may also want to change these.
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet. You definitely want to change this. This part populates your set. 
        $arrSet = $global:VAULT_NODES
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    begin {
        Test-VaultSessionVariable -CheckFor 'Nodes','Token','Cred','LoginMethod'

        $vaultNode = $PsBoundParameters['VaultNode']

        $unsealKey = Read-Host -AsSecureString -Prompt 'Please provide a single Unseal Key'

        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($unsealKey)
        $plainUnsealKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    }
    
    process {
        $jsonPayload = @"
{
    "key": "$plainUnsealKey"
}
"@

        $uri = "https://$vaultNode"

        $irmParams = @{
            Uri    = "$uri/v1/sys/unseal"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Put'
            Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
        }

        try {
            $unsealProgress = Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }

        switch ($OutputType) {
            "Json" {
                $unsealProgress | ConvertTo-Json
            }

            'PSObject' {
                $unsealProgress
            }
        }
        
    }

    end {
        #Delete all traces of variables that could contain a plaintext password.
        $jsonPayload = $null
        $irmParams   = $null
        [System.GC]::Collect()
    }    
}

Set-Alias -Name 'Unseal-Vault' -Value 'Unprotect-Vault'