function ConvertTo-PSCredential {
<#
.Synopsis
    Converts the result of Get-VaultKVSecret or Get-VaultCubbyhole into a PSCredential.

.DESCRIPTION
    ConvertTo-PSCredential consumes the result of Get-VaultKVSecret or Get-VaultCubbyhole and converts the resulting object into a PSCredential.

.EXAMPLE
    PS> Get-VaultKVSecret -Engine dsc -SecretsPath DSCSvcAccount | ConvertTo-PSCredential

    UserName                                   Password
    --------                                   --------
    WAYFAIRDEV\sa_dscadmin System.Security.SecureString

.EXAMPLE
    PS> ConvertTo-PSCredential -InputObject $(Get-VaultKVSecret -Engine dsc -SecretsPath DSCSvcAccount)

    UserName                                   Password
    --------                                   --------
    WAYFAIRDEV\sa_dscadmin System.Security.SecureString

#>
    [CmdletBinding()]
    param(
        #Specifies the Input Object. The input object can be in the form of a Hashtable, PSObject or JSON string.
        [Parameter(
            ValueFromPipeline = $true,
            Position = 0
        )]
        $InputObject
    )

    begin {
        #Array of supported functions.
        $supportedFunctions = @(
            'Get-VaultKVSecret'
            'Get-VaultCubbyholeSecret'
        )

        $psCallStack = Get-PSCallStack

        foreach ($funct in $supportedFunctions) {
            $callStackPosition =  $psCallStack | Where-Object 'Position' -match $funct

            if ($callStackPosition) {
                break
            }
        }

        if ($psCallStack -notmatch "|") {
            #Pipeline was present.
            if (-not $callStackPosition) {
                Write-Error "ConvertTo-PSCredential does not support the specified pipeline input." -ErrorAction 'Stop'
                return
            }
        }
        #else Pipeline not present.
        
    }

    process {
        if ($InputObject -is [Hashtable]) {
            Write-verbose 'Input is hashtable'
            $InputObject = ConvertFrom-Hashtable $([hashtable] $InputObject)
        }
        elseif ($InputObject -is [String]) {
            Write-verbose 'Input is string'
            try {
                $InputObject = $InputObject | ConvertFrom-Json
                Write-verbose 'converted json to psobject'
            }
            catch {
                Write-Error "The specified JSON is malformed and could not be converted to a PSCredential"
                return
            }
        }
        else {
            Write-verbose 'Input is psobject'
        }
        
        $result = Format-VaultOutput -InputObject $InputObject -DataType 'secret_data' -OutputType 'Hashtable' -JustData:$true

        if (-not $result) {
            #If there was no result, the secret could be a Cubbyhole secret; try a different DataType.
            $result = Format-VaultOutput -InputObject $InputObject -DataType 'data' -OutputType 'Hashtable' -JustData:$true
        }

        if ($result) {
            New-Object System.Management.Automation.PSCredential (
                $result.Keys[0], 
                (ConvertTo-SecureString ($result.Values[0]) -AsPlainText -Force)
            )
        }
        
    }

    end {

    }
}