function Get-RawTimeToLive {
<#
.Synopsis
    Returns a specified TimeToLive value in seconds, given a string-formatted TTL value that Vault recognizes.

.DESCRIPTION
    Get-RawTimeToLive returns a specified TimeToLive value in seconds, given a string-formatted TLL value that Vault recognizes.

.EXAMPLE
    PS> Get-RawTimeToLive -TimeToLive 5h

    18000

.EXAMPLE
    PS> Get-RawTimeToLive -TimeToLive 5m

    300
#>
    [CmdletBinding()]
    [OutputType([Int])]
    param(
        [ValidateScript({ $_ -match "^\d+$|^\d+[smh]$" })]
        [String] $TimeToLive
    )

    #Transform each TTL to an Int; the number of seconds the TTL is. 
    switch ($true) {
        ($TimeToLive -match "s") {
            [Int] $rawTTL = $TimeToLive -replace 's',''
        }

        ($TimeToLive -match "m") {
            [Int] $tempTTL = $TimeToLive -replace 'm',''
            [Int] $rawTTL = $tempTTL * 60
        }

        ($TimeToLive -match "h") {
            [Int] $tempTTL = $TimeToLive -replace 'h',''
            [Int] $rawTTL = $tempTTL * 3600
        }

        default {
            [Int] $rawTTL = $TimeToLive
        }
    }

    return $rawTTL
}