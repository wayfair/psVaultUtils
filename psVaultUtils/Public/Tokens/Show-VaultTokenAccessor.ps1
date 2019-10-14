function Show-VaultTokenAccessor {
<#
.Synopsis
    Retrieves accessors for all active tokens.

.DESCRIPTION
    Show-VaultTokenAccessor retrieves accessors for all active tokens.

    This function requires 'sudo' capabilities over the path 'auth/token/accessors'.

.EXAMPLE
    PS> Show-VaultTokenAccessor -JustData | Select-Object -ExpandProperty Keys

    qfOMvaE16JzygFyIcZxSy56j
    6AwiRrQfXIjebiSj96NeROSE
    3ikBVLk56KGqBwhBAtFX2VQu
    tSupKG3HmzXn5u0svx41YQDs
    uPNDSjq2zr36eWVNLEPHyof5
    VhLGl4GhSVDxaXDYOX17b3zx
    ze9Nb2M0RMBbqTTlGg4Qu8yI
    riPvcYB9Q6OvB9af1xt1NU5h
    ZvdNE1kwNqdbhzZYUDVQKZms
    LQ3TWNj5GTVfLJdFnww6Vwlg

.EXAMPLE 
    PS> Show-VaultTokenAccessor -OutputType json
    {
        "request_id":  "bdb76999-035b-0d10-3dd3-e140c25d8d1c",
        "lease_id":  "",
        "renewable":  false,
        "lease_duration":  0,
        "data":  {
                    "keys":  [
                                "qfOMvaE16JzygFyIcZxSy56j",
                                "6AwiRrQfXIjebiSj96NeROSE",
                                "3ikBVLk56KGqBwhBAtFX2VQu",
                                "tSupKG3HmzXn5u0svx41YQDs",
                                "uPNDSjq2zr36eWVNLEPHyof5",
                                "VhLGl4GhSVDxaXDYOX17b3zx",
                                "ze9Nb2M0RMBbqTTlGg4Qu8yI",
                                "riPvcYB9Q6OvB9af1xt1NU5h",
                                "ZvdNE1kwNqdbhzZYUDVQKZms",
                                "LQ3TWNj5GTVfLJdFnww6Vwlg"
                            ]
                },
        "wrap_info":  null,
        "warnings":  null,
        "auth":  null
    }

.EXAMPLE
    PS> Show-VaultTokenAccessor -JustData | Select-Object -ExpandProperty keys | Select-Object -First 1 | Get-VaultTokenAccessor -JustData

    accessor                    : qfOMvaE16JzygFyIcZxSy56j
    creation_time               : 1566502364
    creation_ttl                : 86400
    display_name                : ldap-dev-ben-small
    entity_id                   : 357f788d-75cf-c16d-f6d9-cdbd6c5deee8
    expire_time                 : 2019-08-23T15:32:44.5664492-04:00
    explicit_max_ttl            : 0
    external_namespace_policies :
    id                          :
    identity_policies           : {jenkins-secret-consumer, operator}
    issue_time                  : 2019-08-22T15:32:44.5664492-04:00
    meta                        : @{username=dev-ben-small}
    num_uses                    : 0
    orphan                      : True
    path                        : auth/ldap/login/dev-ben-small
    policies                    : {default}
    renewable                   : True
    ttl                         : 25288
    type                        : service


    This example demonstrates retrieving all of the active accessors, selecting the first one and then sending it down the pipeline to have its properties retrieved.

#>
    [CmdletBinding()]
    param(
        #Specifies how output information should be displayed in the console. Available options are JSON or PSObject.
        [Parameter(
            Position = 0
        )]
        [ValidateSet('Json','PSObject','Hashtable')]
        [String] $OutputType = 'PSObject',

        #Specifies whether or not just the token accessor data should be displayed in the console.
        [Parameter(
            Position = 1
        )]
        [Switch] $JustData
    )

    begin {
        Test-VaultSessionVariable -CheckFor 'Address','Token'
    }

    process {
        $uri = $global:VAULT_ADDR
        
        $body = @{ list = 'true' }

        $irmParams = @{
            Uri    = "$uri/v1/auth/token/accessors"
            Header = @{ "X-Vault-Token" = $global:VAULT_TOKEN }
            Body   = $body
            Method = 'Get'
        }

        try {
            $result = Invoke-RestMethod @irmParams
        }
        catch {
            throw
        }

        $formatParams = @{
            InputObject = $result
            DataType    = 'data'
            JustData    = $JustData.IsPresent
            OutputType  = $OutputType
        }

        Format-VaultOutput @formatParams
    }

    end {

    }
}

Set-Alias -Name 'List-VaultTokenAccessor' -Value 'Show-VaultTokenAccessor'