function Get-VaultRandomBytes {
<#
.Synopsis
    Generates a specified amount of random bytes in either Base64 or Hex format.

.DESCRIPTION
    Get-VaultRandomBytes generates a specified amount of random bytes in either Base64 or Hex format. 

.EXAMPLE
    PS> Get-VaultRandomBytes -Bytes 1024

    request_id     : 42c28bf5-b1d9-d161-a2d9-457cc2a02f21
    lease_id       : 
    renewable      : False
    lease_duration : 0
    data           : @{random_bytes=c174THiVMzUCI+spYLWectH4jDb/cMLB4IGGbPjHoZ7ll5zWv8Dr0tc6Qisk+vcbm5Ta+XWpEYbPfzvvwelS/WhStfeZS
                    2LairkxdD7iAViXiS7XsfBNpjdrwvgtm2C9g+Od1+mN26tiy2YTC0mcMxn4fF1gpl0EPlYWM26WEJ6wIImon6HVdBQIDIucWAO9k6bRokKAd
                    Jevj+DwRvDujteSfqEb7GFoVILd31zMuFlXdr6bFHTxle0KiYhaM/aDu7/JffQfgs/7FdfCSG+FryKCoiXPPpSiO8AoHnKNoGWvKtxkXF5ak
                    KSIGs8dXOZzk/O0TNC04cZrCSfwTFe1qR7gNUP7gLavqAClFaQorNxt5p98Fq/a0VlZUec2KhMq98+pfAg2Jx1qo9D5Sr8gJHGyrMVnMUh3i
                    0uvUB6BpHG/RqBAGTD1A4XXDtBjwuOMM8GGgSad4L6uCSTpSBOxWnip9IiEGqA5BhjBOXNuamKZQ7tA9n7iyaS5QYTH9APuQBIetyOwZ9p7T
                    R7531ON+/vlbeKLza/SdG/Dmi0YSVmeYaGzEQNadPdq1hA76+Quph1MKh8nWNTRFCeo+ZE0DW9AQCD395ngwFKX8+ZPno2zCd+zY6i1Dchtw
                    leBVhjPMAXnT8p+ggm620n2ZtZ9slhfMGSYf+5yZvVpxLEj0p9qIX2JHKOIRpw/xu9/rQ9I3Sf7dShwjSrCNwTcDvqDp0Tw73ajkwbDmlCAG
                    Fg/yCwJohb7XcwE8kR+AUNg8JdIWFdEJ3Pdl9hMzeULSWOA4rYcAqBuAtl5fH5jqop5UABU7qSWM5iMtgWPxchRbOf6CnaFOmewuKpp54xFS
                    INMXuaTUfSqOoTeHBOPe3cFIoRJ7rCMIjC4XlV0coIQ3/Jdx1N4S3u7MdO7zhJzHxOGkzvaqhjkJf1A1PaXFfAVWefAufsIY7QhsrjKkcMS1
                    hoiWqfEhcwKzzg5OPLbIeo0YSgJkKC/g13zrg0OgXIps256ssF5AeyYFULqAgbEDAhAx281/qrrp5vo9j/TEqN/feW/2C4pJq99Z6kVnmlON
                    7LW2IbQyG2Kl+sv/0EHP5jltb2lDDuZ7PvYyfFgtCbueirQz80NO4BggQaPOxegWoYBgJVvq1LdMQNr6T8z+Ynu5M6/QGtPXXvECt84Blznz
                    k8gUjx3rq/3AkerxjtDFVY7oAWDRSl7DPdhhDc8N6el88CzMYM87yMGS+lqn/AIvE+yzu2Wf47iVJ5Wxmd1lloOw3Ea/ug5n51kYw+Jyge6Y
                    f65f+DjmSt4hdgpQpvmtLnsQq9IezGzB9JiksIpGgUn1tfvEJYEkVTdsDydDlzeOj2P/Yw8dhzlAT1AIxucPA==}
    wrap_info      : 
    warnings       : 
    auth           : 

.EXAMPLE 
    PS> Get-VaultRandomBytes -Bytes 16 -Format Hex -OutputType Json -JustData
    {
        "random_bytes":  "67bcd0b94d8ff6b765e19abf99246e7f"
    }
#>
    [CmdletBinding()]
    param(
        #Specifies the number of bytes of data to generate.
        [Parameter(
            Position = 0
        )]
        [Int] $Bytes,

        #Specifies the format the bytes should be returned in. Either Base64 or Hex.
        [Parameter(
            Position = 1
        )]
        [ValidateSet('Base64','Hex')]
        [String] $Format = 'Base64',

        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 2
        )]
        [ValidateSet('Json','PSObject')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the data should be displayed in the console.
        [Parameter(
            Position = 3
        )]
        [Switch] $JustData
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token','Cred','LoginMethod'
    }

    process {
        $jsonPayload = @"
{
    "format": "$($Format.ToLower())"
}
"@

        $uri = $global:VAULT_ADDR

        $irmParams = @{
            Uri    = "$uri/v1/sys/tools/random/$Bytes"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Method = 'Post'
            Body   = $($jsonPayload | ConvertFrom-Json | ConvertTo-Json -Compress)
        }

        try {
            $result = Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }

        switch ($OutputType) {
            'Json' {
                if ($JustData) {
                    $result.data | Select-Object 'random_bytes' | ConvertTo-Json
                }
                else {
                    $result | ConvertTo-Json
                }
            }

            'PSObject' {
                if ($JustData) {
                    $result.data
                }
                else {
                    $result
                }
            }
        }
    }

    end {

    }
}