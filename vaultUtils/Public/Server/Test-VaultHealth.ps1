function Test-VaultHealth {
<#
.Synopsis
    Tests the health of a specified Vault node.

.DESCRIPTION
    Tests the health of a specified Vault node. Returns a status code and array of strings - information about what the status code means as well as the node that was queried.

.EXAMPLE 
    PS> Test-VaultHealth -VaultNode devvault02.domain.com

    Code Status                          Node
    ---- ------                          ----
    200 {Initialized, Unsealed, Active}  devvault02.domain.com

    This example demonstrates the response returned by a unsealed, initialized and active node.

.EXAMPLE
    PS> Test-VaultHealth -VaultNode devvault01.domain.com

    Code Status              Node
    ---- ------              ----
    429 {Unsealed, Standby}  devvault01.domain.com

.EXAMPLE
    PS> Test-VaultHealth -VaultNodeOverride devvault02.domain.com

    Code Status  Node
    ---- ------  ----
    503 {Sealed} devvault02.domain.com

    This example demonstates the response returned by a sealed node, using the VaultNodeOverride parameter.

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
        if ($PSCmdlet.ParameterSetName -eq "Regular") {
            Test-VaultSessionVariable -CheckFor 'Address'
        }

        switch ($PSCmdlet.ParameterSetName) {
            'Regular' { $vaultNode = $PsBoundParameters['VaultNode'] }
            'Override' { $vaultNode = $VaultNodeOverride }
        }
    }

    process {
        $uri = "https://$vaultNode"

        $iwrParams = @{
            Uri    = "$uri/v1/sys/health"
            Method = 'Head'
        }

        try {
            $result = Invoke-WebRequest @iwrParams
            $code = $result.StatusCode
        }
        catch [System.Net.WebException] {
            $code = $_.Exception.Response.StatusCode.value__

            if (-not $code) {
                Write-Error $_
                return
            }
        }
        catch {
            throw
        }

        switch ($code) {
            "200"   { $status = @('Initialized', 'Unsealed', 'Active'); break }
            "429"   { $status = @('Unsealed', 'Standby'); break }
            "472"   { $status = @('Data Recovery Mode Replication Secondary', 'Active'); break }
            "473"   { $status = @('Performance Standby'); break }
            "501"   { $status = @('Not Initialized'); break }
            "503"   { $status = @('Sealed'); break }
            default { $status = @('Unknown') }
        }

        $outobj = [pscustomobject] @{
            Code   = $code
            Status = $status
            Node   = $vaultNode
        }
        
        if ($OutputType -eq "Json") {
            $outobj | ConvertTo-Json
        }
        else {
            $outobj
        }
    }

    end {

    }
}