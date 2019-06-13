#Get public and private function definition files.
$publicFuntions  = @(Get-ChildItem -Path "$PSScriptRoot\Public"  -Recurse -Include *.ps1 -ErrorAction SilentlyContinue)
$privateFuntions = @(Get-ChildItem -Path "$PSScriptRoot\Private" -Recurse -Include *.ps1 -ErrorAction SilentlyContinue)

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

    )