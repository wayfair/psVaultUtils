#Get public and private function definition files.
$publicFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Public"  -Recurse -Include *.ps1 -ErrorAction SilentlyContinue)
$privateFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Private" -Recurse -Include *.ps1 -ErrorAction SilentlyContinue)

#region Add TLS 1.2 to Net.ServcePointManager

if ([Net.ServicePointManager]::SecurityProtocol  -notmatch "Tls12") {
    [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
}

#endregion

#Dot source the files
foreach ($import in @($publicFunctions + $privateFunctions)) {
    try {
        . $import.FullName
    }

    catch {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}

#region Set Global Module Variables

#endregion

Export-ModuleMember `
    -Function $publicFunctions.BaseName `
    -Alias @(
        'Seal-Vault'
        'Unseal-Vault'

        'Stepdown-VaultLeader'

        'Cancel-VaultRekey'
        'Cancel-VaultRekeyVerification'

        'Cancel-VaultRootTokenGeneration'

        'Unwrap-VaultWrapping'
        'Wrap-VaultWrapping'
        'Lookup-VaultWrapping'
        'Rewrap-VaultWrapping'

        'Renew-VaultToken'

        'List-VaultPolicy'

        'List-VaultKVSecret'
        'List-VaultTokenAccessor'
    )