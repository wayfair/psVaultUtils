<#

.SYNOPSIS
    This file is expected to contain build code that will be automatically run by the Windows Gitlab-CI runner.  
	The runner will need a DSC encryption cert and all necessary DSC modules and resources

.DESCRIPTION

.EXAMPLE

.AUTHOR
    Daniel McAvinue
.CHANGELOG
#>

    [CmdletBinding()]

    param(

        [Parameter(Mandatory=$False, Position=0, HelpMessage="Variable to define where these builds will run from, default will point to gitlab-ci 'CI_PROJECT_DIR' variable", ParameterSetName)]
        [ValidateNotNullOrEmpty()]
        [String] $ProjectDirectory=$env:CI_PROJECT_DIR, 

        [Parameter(Mandatory=$False, Position=1, HelpMessage="Variable to define the name of this project, default will point to gitlab-ci 'CI_PROJECT_NAME' variable")]
        [ValidateNotNullOrEmpty()]
        [String] $ProjectName=$env:CI_PROJECT_NAME,

        [Parameter(Mandatory = $True, Position = 2, HelpMessage = 'Version to set for module package')]
        [ValidateNotNullorEmpty()]
        [String] $ModuleVersion,

        [Parameter(Position=3, Mandatory=$False)]
        [ValidateNotNullOrEmpty()]
        $Thumbprint = "44535DB4ACED5E4ED7E18E59E062B79A8C1F6BA3",

        [Parameter(Position=4, Mandatory=$True, HelpMessage="PSGallery to publish against.")]
        [ValidateNotNullOrEmpty()]
        [String] $PSGallery,

        [Parameter(Mandatory = $True, Position = 5, HelpMessage = 'APIKey used to publish to Private PSGallery')]
        [ValidateNotNullorEmpty()]
        [String] $APIKey,

        [Parameter(Mandatory = $False, Position = 6, HelpMessage = 'Private PSGallery Publishing Credential')]
        [ValidateNotNullorEmpty()]
        [PSCredential] $Credential,

        [Parameter(Mandatory = $False, Position = 7, HelpMessage = 'Tags to add to the package when published')]
        [ValidateNotNullorEmpty()]
        [String[]] $Tags,

        [Parameter(Mandatory = $False, Position = 8, HelpMessage = 'Array of slack channels to notify via Hubot')]
        [ValidateNotNullorEmpty()]
        [String] $Notification

    )

Try {

    Import-Module -Name chatbotUtils `
                  -ErrorAction Stop `
                  -Verbose

#region functions

    Function Set-WFRDSCModuleManifest {

        <#
            .SYNOPSIS

            .DESCRIPTION
                Generates or updates a manifest psd1 file for a module

            .EXAMPLE
                Set-WFRDSCModuleManifest -Name dscUtils `
                                -Path . `
                                -Description "This is a test" `
                                -Version 1.0.5 `
                                -Author "Daniel McAvinue" `
                                -ProjectURL "https://git.csnzoo.com/Infra/module-dscUtils" `
                                -Tags @("DSC") `
                                -Verbose

            .AUTHOR
                Daniel McAvinue

            .CHANGELOG  
        #>

        [Cmdletbinding()]

        Param (

            [Parameter(Position=0, Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [String] $Name = $env:CI_PROJECT_NAME,

            [Parameter(Position=1, Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [String] $Path = "$env:CI_PROJECT_DIR\$env:CI_PROJECT_NAME", 

            [Parameter(Position=2, Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [String] $Description="Internal Wayfair Module",

            [Parameter(Position=3, Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [String] $Version,

            [Parameter(Position=4, Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [String] $Author = $env:username,

            [Parameter(Position=5, Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [String] $ProjectURL = $env:CI_PROJECT_URL,

            [Parameter(Position=6, Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [String] $Server = $PSGallery,

            [Parameter(Position=7, Mandatory=$false)]
            [ValidateNotNullOrEmpty()]
            [String[]] $Tags
        )

        BEGIN {
            
            Try {

                $FileList = Get-ChildItem -Path $Path -File -Recurse | Select-Object -ExpandProperty Fullname

                $ManifestPath = Get-ChildItem -Path $Path `
                                            -File `
                                            -Filter "*.psd1" `
                                            -Recurse `
                                            -ErrorAction SilentlyContinue | Select-Object -first 1 -ExpandProperty FullName

                $ModulePath = Get-ChildItem -Path $Path `
                                            -File `
                                            -Filter "*.psm1" `
                                            -Recurse `
                                            -ErrorAction SilentlyContinue | Select-Object -first 1 Name, FullName
                
            }
            Catch {
            
                Write-Warning $_
                exit 1

            }

        }

        PROCESS {

            Try {
                
                If (-not($Version) -and $Server) {

                    Write-verbose "[$Name] Version not defined, detecting auto-increment"

                    $Repository = Get-PSRepository -ErrorAction Stop | Where-Object PublishLocation -eq $Server

                    If (-not($Repository)) {

                        Switch -Regex ($Server) {

                            "https:\/\/dev." {

                                $RepositoryName = 'dev-windows-modules'

                            }
                            "https:\/\/artifactory." {

                                $RepositoryName = 'prod-windows-modules'

                            }

                        }

                        Write-verbose "[$Name] Private Repository not registered, adding"

                        Register-PSRepository -Name $RepositoryName `
                                            -SourceLocation $Server `
                                            -InstallationPolicy Trusted `
                                            -PublishLocation $Server `
                                            -ErrorAction Stop `
                                            -Verbose

                    }
                    Else {

                        Write-verbose "[$Name] Private Repository already registered: '$($Repository.Name)'"
                    }

                    $Repository = Get-PSRepository -ErrorAction Stop | Where-Object PublishLocation -eq $Server

                    $existingmodule = Find-Module -Name $ProjectName `
                                                -Repository $Repository.Name `
                                                -ErrorAction SilentlyContinue
                    
                    If ($existingmodule) {

                        Write-verbose "[$Name] Previous Version '$($existingmodule.Version)'"
                        
                        $previousversion = $existingmodule.Version -split '\.'

                        $previousversion[2] = [int]$previousversion[2]+1

                        $newversion = $previousversion -join "."

                        Write-verbose "[$Name] New Version '$($newversion)'"

                        $Version = $newversion
                    }
                    Else {

                        Write-verbose "[$Name] Existing Module not found on Private Gallery"
                        $Version = '1.0.0'
                    }

                }
                Else {

                    Write-Verbose "Version already defined"

                }

                If ($ManifestPath) {

                    Write-Verbose "[$Name] Module Manifest '$ManifestPath' exists, updating settings"

                    Update-ModuleManifest -Path $ManifestPath `
                                        -Author $Author `
                                        -CompanyName "Wayfair" `
                                        -RootModule $ModulePath.Name `
                                        -ModuleVersion $Version `
                                        -Description $Description `
                                        -Tags $Tags `
                                        -ProjectUri $ProjectURL `
                                        -PowerShellVersion 5.0 `
                                        -FileList $FileList `
                                        -ErrorAction Stop
                }
                Else {

                    Write-Verbose "[$Name] Module Manifest does not exist, creating new manifest"

                    $ManifestPath = $ModulePath.FullName -replace ".psm1", ".psd1"

                    New-ModuleManifest -Path $ManifestPath `
                                    -Guid ([guid]::NewGuid()) `
                                    -Author $Author `
                                    -CompanyName "Wayfair" `
                                    -RootModule $ModulePath.name `
                                    -ModuleVersion $Version `
                                    -Description $Description `
                                    -Tags $Tags `
                                    -ProjectUri $ProjectURL `
                                    -PowerShellVersion 5.0 `
                                    -FileList $FileList `
                                    -ErrorAction Stop
                }
            }
            Catch {

                Write-Warning "[$Name] $_"
                exit 1

            }   
        }

        END {

        }
    }

    Function Set-WFRDSCModuleSpecification {

        <#
            .SYNOPSIS

            .DESCRIPTION
                Generates or updates a nuspec file from a given module manifest

            .DEPENDENCIES
                nuget.commandline needs to be installed
                Powershell 5.0

            .EXAMPLE
                Set-WFRDSCModuleSpecification -Path <PATH TO PSD1 FILE> `
                                            -Verbose


            .AUTHOR
                Daniel McAvinue

            .CHANGELOG  
        #>

        [Cmdletbinding()]

        Param (
            
            [Parameter(Position=0, Mandatory=$false, HelpMessage="Name of Module")]
            [ValidateNotNullOrEmpty()]
            [String] $Name,

            [Parameter(Position=1, Mandatory=$true, HelpMessage="Path to Module Manifest File")]
            [ValidateNotNullOrEmpty()]
            [String] $Path
        )

        BEGIN {

            function ConvertFrom-Xml($XML) {

                ForEach ($Object in @($XML.Objects.Object)) {

                    $PSObject = New-Object PSObject

                    foreach ($Property in @($Object.Property)) {

                        $PSObject | Add-Member NoteProperty $Property.Name $Property.InnerText
                    }

                    $PSObject
                }
            }
        }

        PROCESS {

            Try {
                
                $FileInfo = Get-ChildItem -Path $Path -filter "*.psd1" | Select-Object BaseName, FullName, Directory

                $manifestinfo = Import-PowerShellDataFile -Path $Path `
                                                        -ErrorAction Stop            

                Write-Verbose "Generating NUSPEC file"
                
                # Regenerate NUSPEC file
                Start-Process -FilePath "nuget.exe" `
                            -ArgumentList "spec $($FileInfo.BaseName) -Force -NonInteractive" `
                            -WorkingDirectory $FileInfo.Directory `
                            -ErrorAction Stop `
                            -NoNewWindow `
                            -Wait `
                            -Verbose

                $nuspecfile = "$($FileInfo.Directory)\$($FileInfo.BaseName).nuspec"
                
                Write-Verbose "Updating NUSPEC file based on manifest file '$Path'"

                # Update .nuspec file with information from module manifest
                [xml]$nuspecmanifest = Get-Content -Path $nuspecfile `
                                                    -Filter "*.nuspec" `
                                                    -ErrorAction Stop

                $nuspecmanifest.package.metadata.id = "$($FileInfo.BaseName)"
                $nuspecmanifest.package.metadata.version = $manifestinfo.ModuleVersion
                $nuspecmanifest.package.metadata.authors = $manifestinfo.Author
                $nuspecmanifest.package.metadata.owners = $manifestinfo.Author
                $nuspecmanifest.package.metadata.licenseUrl = $manifestinfo.PrivateData.PSData.ProjectUri
                $nuspecmanifest.package.metadata.dependencies | Where-Object { $_.ParentNode.RemoveChild($_) |out-null}
                $nuspecmanifest.package.metadata.projectUrl = $manifestinfo.PrivateData.PSData.ProjectUri
                $nuspecmanifest.package.metadata.description = $manifestinfo.Description
                $nuspecmanifest.package.metadata.tags = "$($manifestinfo.PrivateData.PSData.Tags)"
            
                $nuspecmanifest.Save($nuspecfile)

            }
            Catch {

                Write-Warning $_
                exit 1

            }   
        }

        END {

        }
    }

    Function New-WFRDSCNugetPackage {

        <#
            .SYNOPSIS

            .DESCRIPTION
                Generate a nuget package froma  provided nuspec file

            .DEPENDENCIES
                nuget.commandline needs to be installed
                Powershell 5.0

            .EXAMPLE
                New-WFRDSCNugetPackage -Path <PATH to NUSPEC FILE>`
                                    -Verbose

            .AUTHOR
                Daniel McAvinue

            .CHANGELOG  
        #>

        [Cmdletbinding()]

        Param (

            [Parameter(Position=0, Mandatory=$false, HelpMessage="Name of Package")]
            [ValidateNotNullOrEmpty()]
            [String] $Name,

            [Parameter(Position=1, Mandatory=$true, HelpMessage="Path to nuspec file")]
            [ValidateNotNullOrEmpty()]
            [String] $Path

        )

        BEGIN {

        }

        PROCESS {

            Try {
    
                $nuspecfile = Get-ChildItem -Path $Path `
                                            -filter "*.nuspec" `
                                            -ErrorAction Stop | Select-Object BaseName, FullName, Directory
        
                # Pack up nupkg file
                Start-Process -FilePath "nuget.exe" `
                            -ArgumentList "pack $($nuspecfile.FullName) -OutputDirectory $($nuspecfile.Directory) -NonInteractive" `
                            -WorkingDirectory $nuspecfile.Directory `
                            -ErrorAction Stop `
                            -NoNewWindow `
                            -Wait 

            }
            Catch {

                Write-Warning $_
                break

            }   
        }

        END {

        }
    }

    Function Publish-WFRDSCNugetPackage {

        <#
            .SYNOPSIS

            .DESCRIPTION
                Publish a provided nuget package to a provided nuget server

            .DEPENDENCIES
                nuget.commandline needs to be installed
                Powershell 5.0

            .EXAMPLE

                Publish-WFRDSCNugetPackage -Path C:\Resources\Projects\Powershell\module-dscUtils\dscUtils\dscUtils.1.0.6.nupkg `
                                -APIKey "xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx" `
                                -Server "http://<NUGETSERVER>:8080/api/v2/package" `
                                -Verbose

            .AUTHOR
                Daniel McAvinue

            .CHANGELOG  
        #>

        [Cmdletbinding(DefaultParameterSetName='Standard')]

        Param (

            [Parameter(Position=0, Mandatory=$true, HelpMessage="Path to .nupkg file", ParameterSetName='Standard')]
            [ValidateNotNullOrEmpty()]
            [String] $Path,

            [Parameter(Position=1, Mandatory=$true, HelpMessage="URL of nuget server", ParameterSetName='Standard')]
            [ValidateNotNullOrEmpty()]
            [String] $Server,

            [Parameter(Position=2, Mandatory=$true, HelpMessage="API Key used to push to the nuget server", ParameterSetName='Standard')]
            [ValidateNotNullOrEmpty()]
            [String] $APIKey

        )

        BEGIN {

        }

        PROCESS {

            Try {
    
                $nupkgfile = Get-ChildItem -Path $Path -filter "*.nupkg" -ErrorAction Stop| Select-Object Name, BaseName, FullName, Directory
        
                # Push nupkg file to server
                Start-Process -FilePath "nuget.exe" `
                            -ArgumentList "push $($nupkgfile.Name) -Source $Server -NonInteractive" `
                            -WorkingDirectory $nupkgfile.Directory `
                            -ErrorAction Stop `
                            -NoNewWindow `
                            -Wait

            }
            Catch {

                Write-Warning $_
                exit 1

            }   
        }

        END {

        }
    }

#endregion

    # Generate module manifest if it doesn't exist
    Set-WFRDSCModuleManifest -Name $ProjectName `
                             -Path "$ProjectDirectory\$ProjectName" `
                             -Version $ModuleVersion `
                             -Description $ProjectName `
                             -Author $env:GITLAB_USER_EMAIL `
                             -Tags $Tags `
                             -ErrorAction Stop `
                             -Verbose
    
    # Generate the nuspec files based on the module manifest
    Set-WFRDSCModuleSpecification -Path "$ProjectDirectory\$ProjectName\$ProjectName.psd1" `
                                  -ErrorAction Stop `
                                  -Verbose

    # Generate .nupkg file based on .nuspec file
    New-WFRDSCNugetPackage -Path "$ProjectDirectory\$ProjectName\$ProjectName.nuspec" `
                           -ErrorAction Stop `
                           -Verbose

    # Publish nupkg file to gallery

    $nugetpackage = Get-Childitem -Path "$ProjectDirectory\$ProjectName" `
                                  -Filter '*.nupkg' `
                                  | Select-Object -ExpandProperty FullName
    
    Publish-WFRDSCNugetPackage -Path $nugetpackage `
                               -Server $PSGallery `
                               -APIKey $APIKey `
                               -ErrorAction Stop `
                               -Verbose

    If ($Notification) {

        $Rooms = $Notification -split ","

        ForEach ($Room in $Rooms) {
        
            Send-ChatBotMessageToRoom -Message "$ProjectName - $env:CI_PROJECT_URL`n`tEnvironment:$env:CI_ENVIRONMENT_NAME`n`tPipeline:$env:CI_PROJECT_URL/pipelines/$env:CI_PIPELINE_ID`n`tStatus:Success`n`tMessage:Pipeline deployed successfully" -Room $Room -Verbose
        }

    }
        
}
Catch {

    Write-Warning $_

    If ($Notification) {

        $Rooms = $Notification -split ","        

        ForEach ($Room in $Rooms) {

            Send-ChatBotMessageToRoom -Message "$ProjectName - $env:CI_PROJECT_URL`n`tEnvironment:$env:CI_ENVIRONMENT_NAME`n`tPipeline:$env:CI_PROJECT_URL/pipelines/$env:CI_PIPELINE_ID`n`tStatus:Failed`n`tMessage:$_" -Room $Room -Verbose
        }

    }
    
    Write-Warning $_
    EXIT 1

}

