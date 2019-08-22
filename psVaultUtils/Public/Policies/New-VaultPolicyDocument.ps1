function New-VaultPolicyDocument {
<#
.Synopsis
    Created an instance of an HCL-formatted policy document that can be added to a policy.

.DESCRIPTION
    New-VaultPolicyDocument creates an instance of an HCL-formatted policy document that can be added to a policy.

    Additional documentation regarding Fine-Grained Control can be found on Hashicorp's website: 
    https://www.vaultproject.io/docs/concepts/policies.html#fine-grained-control

.EXAMPLE
    PS> New-VaultPolicyDocument -PolicyPath "dsc/*" -PolicyCapabilities Create, Read, Update, Delete, List -PolicyComment "Allows a token to manage the DSC KV"

    #Allows a token to manage the DSC KV
    path "dsc/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

.EXAMPLE
    PS> New-VaultPolicyDocument -PolicyPath "dsc/SQLAG/conf_ag/*" -PolicyCapabilities Create,Deny -PolicyComment "Denies a token from accessing the /conf_ag secret path." -PolicyMaximumWrappingTTL 5h

    WARNING: The 'Deny' capability cannot be mixed with other capabilities. Capabilities other than 'Deny' have been removed.

    #Denies a token from accessing the /conf_ag secret path.
    path "dsc/SQLAG/conf_ag/*" {
      capabilities = ["deny"]
      max_wrapping_ttl = 5h
    }

    This example demonstrates what happens when any other capability is specified along with the 'Deny' capability.

.EXAMPLE
    PS> $policyDoc = New-VaultPolicyDocument -PolicyPath "dsc/*" -PolicyCapabilities Create, Read, Update, Delete, List -PolicyComment "Allows a token to manage the DSC KV"

    PS> New-VaultPolicy -PolicyName 'dsc-secret-consumer' -PolicyDocuments $policyDoc

    This example demonstrates first building a policy document, and then specifying it when creating a new policy.
#>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        #Specifies the path that will policy will be created for.
        [Parameter(
            Mandatory = $true,
            Position = 0
        )]
        [String] $PolicyPath,

        #Specifies one or more capabilities that will be associated with the policy path.
        #If the 'Deny' capability is specified, any other specified capabilities are ignored/filtered.
        #
        #Capabilities:
        #   * Create - Allows creating data at the given path. Very few parts of Vault distinguish between create and update, so most operations require both create and update capabilities.
        #   * Read - Allows reading the data at the given path.
        #   * Update - Allows changing the data at the given path. In most parts of Vault, this implicitly includes the ability to create the initial value at the path.
        #   * Delete - Allows deleting the data at the given path.
        #   * List - Allows listing values at the given path. Note that the keys returned by a list operation are not filtered by policies. Do not encode sensitive information in key names. Not all backends support listing.
        #   * Sudo - Allows access to paths that are root-protected. Tokens are not permitted to interact with these paths unless they are have the sudo capability (in addition to the other necessary capabilities for performing an operation against that path, such as read or delete).
        #   * Deny - Disallows access. This always takes precedence regardless of any other defined capabilities, including sudo.
        [Parameter(
            Mandatory = $true,
            Position = 1
        )] 
        [ValidateSet('Create','Read','Update','Delete','List','Sudo','Deny')]
        [Alias('Capabilities')]
        [String[]] $PolicyCapabilities,

        #Specifies one or more hashtables of allowed policy parameters. Whitelists a list of keys and values that are permitted on the given path.
        [Parameter(
            Position = 2
        )]
        [Alias('AllowedParameters')] 
        [Hashtable[]] $PolicyAllowedParameters,

        #Specifies one or more hashtables of denied policy parameters. Blacklists a list of parameter and values. Any values specified here take precedence over allowed policy parameters.
        [Parameter(
            Position = 3
        )]
        [Alias('DeniedParameters')]  
        [Hashtable[]] $PolicyDeniedParameters,

        #Specifies one or more required policy parameters.
        [Parameter(
            Position = 4
        )]
        [Alias('RequiredParameters')]  
        [String[]] $PolicyRequiredParameters,

        #Specifies a Minimum Wrapping TTL.
        [Parameter(
            Position = 5
        )]
        [Alias('MinimumWrappingTTL')] 
        [ValidateScript({ $_ -match "^\d+$|^\d+[smh]$" })]
        [String] $PolicyMinimumWrappingTTL,

        #Specified a Maximum Wrapping TTL.
        [Parameter(
            Position = 6
        )]
        [Alias('MaximumWrappingTTL')] 
        [ValidateScript({ $_ -match "^\d+$|^\d+[smh]$" })]
        [String] $PolicyMaximumWrappingTTL,

        #Specifies a comment/decription that should be associated with the policy document.
        [Parameter(
            Position = 7
        )]
        [Alias('Comment')]  
        [String] $PolicyComment
    )

    begin {
        
    }

    process {
        #region Handle Min/Max TTL

        $rawMinTTL = Get-RawTimeToLive -TimeToLive $PolicyMinimumWrappingTTL -ErrorAction 'SilentlyContinue'
        $rawMaxTTL = Get-RawTimeToLive -TimeToLive $PolicyMaximumWrappingTTL -ErrorAction 'SilentlyContinue'

        if ($rawMaxTTL -lt $rawMinTTL) {
            Write-Error "The MaximumWrappingTTL cannot be less than the MinimumWrappingTTL."
            return
        }

        #endregion

        #region Handle Deny in Policy

        if (($PolicyCapabilities -contains 'Deny') -and ($($PolicyCapabilities | Measure-Object | Select-Object -ExpandProperty 'Count') -gt 1)) {
            $PolicyCapabilities = @('Deny')
            Write-Warning "The 'Deny' capability cannot be mixed with other capabilities. Capabilities other than 'Deny' have been removed."
            Write-Host ""
        }

        #endregion

        #region Create a here-string of allowed policy parameters

        if ($PolicyAllowedParameters) {
            $papBegin = "allowed_parameters = {"

            $papLines = $null
            foreach ($element in $PolicyAllowedParameters.GetEnumerator()) {
                $name  = "  $($element.Keys) = "
                $value = [String[]] $element.Values -split " "

                if ($value) {
                    $value = "[`"$($value -join '","')`"]"
                }
                else {
                    $value = "[]"
                }

                [Array] $papLines += $name + $value
            }

            $papEnd = "}"

            $pap = @"
  $papBegin
  $($paplines -join "`n  ")
  $papEnd
"@
        }

        #endregion

        #region Create a here-string of denied policy parameters

        if ($PolicyDeniedParameters) {
            $pdpBegin = "denied_parameters = {"

            $pdpLines = $null
            foreach ($element in $PolicyDeniedParameters.GetEnumerator()) {
                $name  = "  $($element.Keys) = "
                $value = [String[]] $element.Values -split " "

                if ($value) {
                    $value = "[`"$($value -join '","')`"]"
                }
                else {
                    $value = "[]"
                }

                [Array] $pdpLines += $name + $value
            }

            $pdpEnd = "}"

            $pdp = @"
  $pdpBegin
  $($pdplines -join "`n  ")
  $pdpEnd
"@
        }
        
        #endregion

        #region Create a here-string of required policy parameters

        if ($PolicyRequiredParameters) {
            $prp = @"
  required_parameters = ["$($PolicyRequiredParameters -join '", "')"]            
"@
        }

        #endregion

        #region Create a here-string of Min/Max Wrap TTLs

        if ($PolicyMinimumWrappingTTL) {
            $minTTL = "  min_wrapping_ttl = $PolicyMinimumWrappingTTL"
        }

        if ($PolicyMaximumWrappingTTL) {
            $maxTTL = "  max_wrapping_ttl = $PolicyMaximumWrappingTTL"
        }

        #region Create Payload

            <# JSON-Formatted Policy Document Code
            
            #This code would consume the parameters of the function, create a PSObject, and then convert it to JSON.
            #This code is much cleaner than building an HCL-formatted string containing a policy document, 
            #however, JSON has the limitation of not supporting comments, and additionally the JSON spacing looks terrible.

            #Ideally, this code would create a PSObject, convert the PSObject to JSON, then convert the JSON to HCL, and either prepend or append the comment.
            #Writing a tool to convert JSON to HCL in PowerShell/C#/DotNet is beyond my capabilities.

            #This code will remain in the file, but commented out to save someone the legwork of 
            #rewriting it if Hashicorp should decided to add a tool/API endpoint for converting JSON to HCL and vice versa.

            $payload = [pscustomobject] @{
                path = [pscustomobject] @{ 
                    $PolicyPath = [pscustomobject] @{
                        capabilities = $PolicyCapabilities.ToLower()
                    }
                }
            }

            if ($PolicyComment) {
                $payload.path | Add-Member -MemberType 'NoteProperty' -Name 'comment' -Value $PolicyComment
            }

            if ($PolicyAllowedParameters) {
            $payload.path.$PolicyPath | Add-Member -MemberType 'NoteProperty' -Name 'allowed_parameters' -Value $PolicyAllowedParameters
            }

            if ($PolicyDeniedParameters) {
                $payload.path.$PolicyPath | Add-Member -MemberType 'NoteProperty' -Name 'denied_parameters' -Value $PolicyDeniedParameters
            }

            if ($PolicyRequiredParameters) {
                $payload.path.$PolicyPath | Add-Member -MemberType 'NoteProperty' -Name 'required_parameters' -Value $PolicyRequiredParameters
            }

            $policyPayload = $($payload | ConvertTo-Json -Depth 10) -replace '""','[]'
            #>

        $policyPayload = ""

        if ($PolicyComment) {
            $policyPayload += "#$PolicyComment`n"
        }

        $policyPayload += @"
path "$PolicyPath" {
  capabilities = ["$($PolicyCapabilities.ToLower() -join '", "')"]`n
"@

        if ($pap) {
            $policyPayload += "$pap`n"
        }

        if ($pdp) {
            $policyPayload += "$pdp`n"
        }

        if ($prp) {
            $policyPayload += "$prp`n"
        }

        if ($minTTL) {
            $policyPayload += "$minTTL`n"
        }

        if ($maxTTL) {
            $policyPayload += "$maxTTL`n"
        }

        $policyPayload += "}"

        #endregion

        Write-Output $policyPayload.TrimStart()
    }

    end {

    }
}