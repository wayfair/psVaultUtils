<#
    .Synopsis
         Pester Tests used against modules.
         Build process should deploy to PSPrivateGallery on success.

    .Description

    .Author
        Daniel McAvinue 
        
    .Date
        06-02-17
#>

[CmdletBinding()]

Param(

    [Parameter(Position=0, Mandatory=$False, HelpMessage="Variable to define where these builds will run from, default will point to gitlab-ci 'CI_PROJECT_DIR' variable")]
    [ValidateNotNullOrEmpty()]
    [String] $ProjectDirectory, 

    [Parameter(Position=1, Mandatory=$False, HelpMessage="Variable to define the name of this project, default will point to gitlab-ci 'CI_PROJECT_NAME' variable")]
    [ValidateNotNullOrEmpty()]
    [String] $ProjectName, 

    [Parameter(Position=2, Mandatory=$False, HelpMessage="Variable to define the Version of this Module")]
    [ValidateNotNullOrEmpty()]
    [String] $ModuleVersion, 

    [Parameter(Position=3, Mandatory=$False, HelpMessage="PSGallery to test this module against")]
    [ValidateNotNullOrEmpty()]
    [String[]] $ModuleRepository

)

#region setup

    $ErrorActionPreference = "Stop"

    # Check that the runner has the necessary nuget provider and module repositories.
    Try {
        
        # Import Pester module
        Import-Module -Name Pester `
                      -ErrorAction SilentlyContinue
        
        # Test for nuget package provider, if it doesn't exist, install it.
        
        $testnugetprovider = Get-PackageProvider -ErrorAction SilentlyContinue `
                                | Where-Object Name -eq Nuget

        If (-not($testnugetprovider )) {
            <#
            Copy-Item -Path "\\csnzoo.com\services\infra\dsc_source_files\Packages\NugetProvider\nuget" `
                      -Destination "C:\Program Files\PackageManagement\ProviderAssemblies\nuget" `
                      -Force `
                      -ErrorAction Stop
            #>
            Write-Verbose "[FAILURE] Nuget PackageProvider needs to be installed."
            throw
        }
        Else {

            Write-Verbose "[SUCCESS] Nuget PackageProvider is registered."
        }

        
    }
    Catch {

        $e = $_.Exception
        $line = $_.InvocationInfo.ScriptLineNumber
        $msg = $e.Message 

        Write-Warning "[$line] $msg"
        throw
    }

#endregion

#region Module Tests

    Describe "Package-Tests" -Tags @("Dev") {

        Try {

            ForEach ($Repository in $ModuleRepository) {

                # Test for registered private gallery, if it doesn't exist, register it.
                It "[$Repository] Repository should exist" {
                
                    $testrepository = Get-PSRepository -Name $Repository `
                                                       -ErrorAction Stop

                    $testrepository.Name | Should Be $Repository
                }

                $Modules = Find-Module -Name $ProjectName `
                                          -Repository $Repository

                ForEach ($Module in $Modules) {

                    # Test Module Repository for existing package
                    It "[$Repository][Modules][$($Module.Name)] Version '$ModuleVersion' should be greater than $($Module.Version)" {   

                        [Version]$newversion = $ModuleVersion
                        [Version]$oldversion = $Module.Version 

                        $newversion | Should BeGreaterThan $oldversion
                    }
                }
            }        
        }
        Catch {

            $e = $_.Exception
            $line = $_.InvocationInfo.ScriptLineNumber
            $msg = $e.Message 

            Write-Warning "[$line] $msg"
        }

    }
    
#endregion