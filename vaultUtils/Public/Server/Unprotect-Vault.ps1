function Unprotect-Vault {
<#
.Synopsis
    Unseals a specified vault node.

.DESCRIPTION
    Unprotect-Vault unseals a vault node, specified by its hostname. 

    It might not be immediately clear, but this command does not require a token, 
    because a token cannot be acquired if vault is sealed, especially if all nodes are sealed.


DYNAMIC PARAMETERS
    -VaultNode
        Specifies the hostname of a sealed node.

.EXAMPLE
    PS> Unprotect-Vault -VaultNode devbo1chvault01.devcorp.wayfair.com
    Please provide a single Unseal Key: ********************************************

    type          : shamir
    initialized   : True
    sealed        : True
    t             : 3
    n             : 5
    progress      : 1
    nonce         : 464eeae3-d1a1-bd1e-e49b-627a6fb5b5ba
    version       : 1.1.2
    migration     : False
    recovery_seal : False

    Vault is now one-third of the way unsealed. 

.EXAMPLE
    PS> Unprotect-Vault -VaultNodeOverride devbo1chvault02.devcorp.wayfair.com

    cmdlet Set-VaultSessionVariable at command pipeline position 1
    Supply values for the following parameters:
    VaultURL: https://hvault.devcorp.wayfair.com
    LoginMethod: ldap

    cmdlet Get-Credential at command pipeline position 1
    Supply values for the following parameters:
    Credential
    Please provide a single Unseal Key: ********************************************

    type          : shamir
    initialized   : True
    sealed        : True
    t             : 3
    n             : 5
    progress      : 2
    nonce         : 464eeae3-d1a1-bd1e-e49b-627a6fb5b5ba
    version       : 1.1.2
    migration     : False
    recovery_seal : False


    In this example, for any number of reasons, $VAULT_NODES did not contain the nodes in the cluster. 
    Instead of specifying a vault node via -VaultNode, we specify the node we want to unseal via -VaultNodeOverride.

    Because $VAULT_NODES (and potentially other important variables) is/are not populated, Set-VaultSessionVariable is 
    executed at runtime, and the person running Unprotect-Vault is prompted to enter a few parameters to 
    populate variables like: VAULT_ADDR, VAULT_LOGIN_METHOD and VAULT_CRED.

    Vault is now two-thirds of the way unsealed.
#>
    [CmdletBinding(
        DefaultParameterSetName = 'Regular'
    )]
    param(
        #Specifies the hostname of a sealed node. Use when $VAULT_NODES is not poplated and one or all vault nodes are sealed.
        [Parameter(
            ParameterSetName = 'Override',
            Position = 1   
        )]
        [String] $VaultNodeOverride,

        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 2
        )]
        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject'
    )

    DynamicParam {
        $oldEAP = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        # Set the dynamic parameters' name.
        $ParameterName = 'VaultNode'
    
        # Create the dictionary 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    
        # Create and set the parameters' attributes. You may also want to change these.
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.ParameterSetName = 'Regular'
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 0

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

        $ErrorActionPreference = $oldEAP
        return $RuntimeParameterDictionary
    }

    begin {
        Test-VaultSessionVariable -CheckFor 'Nodes','Token','Cred','LoginMethod'

        switch ($PSCmdlet.ParameterSetName) {
            'Regular' { $vaultNode = $PsBoundParameters['VaultNode'] }
            'Override' { $vaultNode = $VaultNodeOverride }
        }

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