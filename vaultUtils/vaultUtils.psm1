#Get public and private function definition files.
$publicFuntions  = @(Get-ChildItem -Path "$PSScriptRoot\Public"  -Recurse -Include *.ps1 -ErrorAction SilentlyContinue)
$privateFuntions = @(Get-ChildItem -Path "$PSScriptRoot\Private" -Recurse -Include *.ps1 -ErrorAction SilentlyContinue)

#region Add TLS 1.2 to Net.ServcePointManager

if ([Net.ServicePointManager]::SecurityProtocol  -notmatch "Tls12") {
    [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
}

#endregion

#Dot source the files
foreach ($import in @($publicFuntions + $privateFuntions)) {
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
    -Function $publicFuntions.BaseName `
    -Alias @(
        'Seal-Vault'
        'Unseal-Vault'

        'Stepdown-VaultLeader'

        'Cancel-VaultRekey'
        'Cancel-VaultRekeyVerification'

        'Unwrap-VaultWrapping'
        'Wrap-VaultWrapping'
        'Lookup-VaultWrapping'
        'Rewrap-VaultWrapping'

        'Renew-Token'
    )