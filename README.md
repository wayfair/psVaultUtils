# Synopsis
psVaultUtils is a module for interacting with Hashicorp Vault.

# Author
Ben Small `bsmall[at]wayfair.com`

## Author's Note
This is my first open source project. Please bear with me while I stumble through the proper way to manage branches and perform pull requests when external parties are involved. Thank you for your patience.

# Module Limitations
* LDAP is currently the only supported authentication method besides token authentication, which is implicitly supported. 
* A function to initialize a new Vault instance/cluster is not currently present.
* Sets of functions to interact with engines other than _KV_ and _Cubbyhole_ are not currently present.
* Sets of functions and/or parameters to interact with _enterprise features_ are generally not present.

# Verb Mapping // Command Aliases

Hashicorp Vault uses several "verbs", which, according to PowerShell standards are considered unapproved, and make commands less discoverable. 

Consider the possibility that someone who is familiar with Vault, but not PowerShell might intuit certain commands based on Vault nomenclature. 
The following verb mappings and command alises might actually make a person who is familiar with Vault, but not familiar with Powershell more discoverable:

## Wraping Verbs & Command Aliases

* Wrap --> New
* Unwrap --> Get
* Rewrap --> Update
* Lookup --> Show

<br>

* New-VaultWrapping --> Wrap-VaultWrapping
* Get-VaultWrapping --> Unwrap-VaultWrapping
* Update-VaultWrapping --> Rewrap-VaultWrapping
* Show-VaultWrapping --> Lookup-VaultWrapping

## Seal / Unseal / Stepdown Verbs & Command Aliases

* Seal --> Protect
* Unseal --> Unprotect
* Stepdown --> Revoke

<br>

* Protect-Vault --> Seal-Vault
* Unprotect-Vault --> Unseal-Vault
* Revoke-VaultLeader --> Stepdown-VaultLeader

## Keys & Token Verbs & Command Aliases

* Cancel --> Stop
* Renew --> Update

<br>

* Stop-VaultRekey --> Cancel-VaultRekey
* Stop-VaultRekeyVerification --> Cancel-VaultRekeyVerification
* Stop-VaultRootTokenGeneration --> Cancel-VaultRootTokenGeneration
* Update-VaultToken --> Renew-VaultToken

# Command Usage

## Setting Up Vault Variables

Before you can run most commands, you need to set some global variables:

```
PS> $cred = Get-Credential 

PS> Set-VaultSessionVariable -VaultURL https://vault.domain.com -Credential $cred -LoginMethod LDAP
```

You can see all of the Vault-specific variables that are set by executing:

```powershell
PS> Get-VaultSessionVariable

Name                           Value
----                           -----
VAULT_ADDR                     https://active.vault.service.consul.domain.com
VAULT_ADDR_STANDBY             https://standby.vault.service.consul.domain.com
VAULT_CRED                     System.Management.Automation.PSCredential
VAULT_LOGIN_METHOD             LDAP
VAULT_NODES                    {devvault02.domain.com, devvault01.domain.com}
```

NOTE: to prevent a `VAULT_TOKEN` from being written to a PSTranscript, PSTranscripting is turned off, if it was previously on.

## Getting the Status of Vault

With `VAULT_ADDR` defined, we can now poll the status of Vault:

```powershell
PS> Get-VaultStatus

seal_type       : shamir
initialized     : True
sealed          : False
total_shares    : 5
threshold       : 3
version         : 1.1.2
cluster_name    : vault-cluster-47802c8f
cluster_id      : 9708a39d-dd9c-017f-333a-5551e83d9be7
cluster_leader  : https://devvault02.domain.com:443
server_time_utc : 7/1/2019 2:17:53 PM +00:00
ha_enabled      : True
```

Beyond that, we can't do much else though, because we need a `VAULT_TOKEN` to perform authenticated actions...

## Getting A Vault Token For Authentication

The next pair of commands to execute, to complete to "setup" process is:

```powershell
PS> Get-VaultLoginToken | Set-VaultLoginToken
```

Doing so will create another global variable `VAULT_TOKEN`, which will be used to authenticate you to Hashicorp Vault instance defined in `VAULT_ADDR`.

You are now "authenticated" to Vault. From here, you can:
* Create/Read KV secrets your token has access to. 
* Read/Update KV secret engine.
* Wrap, unwrap and/or rewrap data, as well as lookup wrapped data information.
* Generate random byte information in Base64 or Hex formats.
* Generate SHA2 hashes for Base64 or Hex-encoded information.
* Additionally, if your token has administrative capabilities, you can seal vault, or tell the active node to step down. 


## Interacting with Engines & Secrets

### Getting a KV Secret

```powershell
PS> Get-VaultKVSecret -Engine dsc -SecretsPath sql_ag/conf_ag -OutputType PSObject -JustData

foo
---
bar
```

### Getting Information about a KV Engine

```powershell
PS> Get-VaultKVEngine -Engine dsc


request_id     : 3aea0b51-2f58-3aae-07b8-76da6164e91b
lease_id       :
renewable      : False
lease_duration : 0
data           : @{cas_required=False; max_versions=0}
wrap_info      :
warnings       :
auth           :
```

### Creating a Secret in a KV Engine

```powershell
PS> New-VaultKVSecret -Engine test-kv -SecretsPath foo/bar -Secrets @{'foo'='bar'}


request_id     : 483a1675-fc72-f32e-f5db-6d8e8f585488
lease_id       :
renewable      : False
lease_duration : 0
data           : @{created_time=2019-07-02T20:50:04.8770458Z; deletion_time=; destroyed=False; version=1}
wrap_info      :
warnings       :
auth           :
```

### Getting a Secret's Metadata

```powershell
PS> Get-VaultKVSecret -Engine test-kv -SecretsPath foo/bar -MetaData -OutputType Json
{
    "request_id":  "5825a510-63c0-bcb2-fa37-c8f9adaacbb6",
    "lease_id":  "",
    "renewable":  false,
    "lease_duration":  0,
    "data":  {
                 "cas_required":  false,
                 "created_time":  "2019-07-02T20:50:04.8770458Z",
                 "current_version":  1,
                 "max_versions":  0,
                 "oldest_version":  0,
                 "updated_time":  "2019-07-02T20:50:04.8770458Z",
                 "versions":  {
                                  "1":  "@{created_time=2019-07-02T20:50:04.8770458Z; deletion_time=; destroyed=False}"
                              }
             },
    "wrap_info":  null,
    "warnings":  null,
    "auth":  null
}
```

## Interacting with Tokens & Accessors

### Creating a New Token

```powershell
PS> New-VaultToken

request_id     : 509ad951-ad19-de93-01ad-2c9864a0d2b8
lease_id       :
renewable      : False
lease_duration : 0
data           :
wrap_info      :
warnings       :
auth           : @{client_token=s.tOZMiBe0WkpZ4NeUCXKdrvVA; accessor=kQdhTOrp5IEJ3NlLuhP2lhKp; policies=System.Object[];
                 token_policies=System.Object[]; identity_policies=System.Object[]; metadata=; lease_duration=129600;
                 renewable=False; entity_id=357f788d-75cf-c16d-f6d9-cdbd6c5deee8; token_type=service; orphan=False}
```

```powershell
PS> $newTokenParams = @{
>>      RoleName = 'SomeRole'
>>      Policies = 'jenkins-secret-consumer'
>>      MetaData = @{ 'user'='ben.small' }
>>      Renewable = $true
>>      TimeToLive = "48h"
>>      DisplayName = "ben.small"
>>      NumberOfUses = 10
>>  }

PS> New-VaultToken @newTokenParams

request_id     : ec54b2f4-c538-d102-3273-6b7215cc2ba6
lease_id       :
renewable      : False
lease_duration : 0
data           :
wrap_info      :
warnings       :
auth           : @{client_token=s.Ezg2ZSLaKcs8g3I32BQrBU3H; accessor=xa06uj4p0vaVMcpYrVHviw1Y; policies=System.Object[];
                token_policies=System.Object[]; identity_policies=System.Object[]; metadata=; lease_duration=172800;
                renewable=True; entity_id=357f788d-75cf-c16d-f6d9-cdbd6c5deee8; token_type=service; orphan=False}
```

### Updating the Lease/TTL of a Token

```powershell
PS> Update-VaultToken -Token s.9xLfaE97zipyovfM9owMbqSl -Increment 200h

request_id     : b21dde75-0f9f-14a3-c1d7-d3ceb1ad32c2
lease_id       :
renewable      : False
lease_duration : 0
data           :
wrap_info      :
warnings       :
auth           : @{client_token=s.9xLfaE97zipyovfM9owMbqSl; accessor=nGxVOLVniYtviucozXPZCF0B; policies=System.Object[];
                 token_policies=System.Object[]; metadata=; lease_duration=720000; renewable=True;
                 entity_id=357f788d-75cf-c16d-f6d9-cdbd6c5deee8; token_type=service; orphan=False}
```

### Revoking a Token

```powershell
PS> Get-VaultToken -Token s.9xLfaE97zipyovfM9owMbqSl | Revoke-VaultToken

Confirm
Are you sure you want to perform this action?
Performing the operation "Revoke Vault token" on target "s.9xLfaE97zipyovfM9owMbqSl".
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): y
```

### Viewing & Revoking Token Accessors

```powershell
PS> Get-VaultTokenAccessor -Accessor mqzm7rTDXZIeZnF357znsZdZ


request_id     : dc3b1ac0-a253-d4da-16b0-c7aae18351a2
lease_id       :
renewable      : False
lease_duration : 0
data           : @{accessor=mqzm7rTDXZIeZnF357znsZdZ; creation_time=1562101179; creation_ttl=172800;
                 display_name=token-ben.small; entity_id=357f788d-75cf-c16d-f6d9-cdbd6c5deee8;
                 expire_time=2019-07-04T16:59:39.5071214-04:00; explicit_max_ttl=0; external_namespace_policies=; id=;
                 identity_policies=System.Object[]; issue_time=2019-07-02T16:59:39.5071214-04:00; meta=; num_uses=10;
                 orphan=False; path=auth/token/create; policies=System.Object[]; renewable=True; ttl=172782; type=service}
wrap_info      :
warnings       :
auth           :
```

```powershell
Get-VaultTokenAccessor -Accessor mqzm7rTDXZIeZnF357znsZdZ | Revoke-VaultTokenAccessor -Confirm:$false
```

## Interacting with Vault Tools

### Wrapping KV Information

```powershell
PS> New-VaultWrapping -WrapData @{'zip'='zap'} -WrapTTL 5h -OutputType PSObject

request_id     :
lease_id       :
renewable      : False
lease_duration : 0
data           :
wrap_info      : @{token=s.6z8pEEAxFqaQ91HiVcWNMmVC; accessor=bdPmeKWeu05muP6ND4lyZ4uu; ttl=18000;
                 creation_time=2019-07-01T10:32:51.4449314-04:00; creation_path=sys/wrapping/wrap}
warnings       :
auth           :
```

### Show Wrapped KV Information

Using the token from the example above, show information about the wrapped data (but not the data itself):

```powershell
PS> Show-VaultWrapping -Token s.6z8pEEAxFqaQ91HiVcWNMmVC

request_id     : 7d990020-0615-c293-548a-fb810ee63b16
lease_id       :
renewable      : False
lease_duration : 0
data           : @{creation_path=sys/wrapping/wrap; creation_time=2019-07-01T10:32:51.4449314-04:00; creation_ttl=18000}
wrap_info      :
warnings       :
auth           :
```

### Retrieve Wrapped KV Information

Using the same token from the two examples above, retrieve wrapped data:

```powershell
PS> Get-VaultWrapping -Token s.6z8pEEAxFqaQ91HiVcWNMmVC -OutputType Json
{
    "request_id":  "e5732ad5-e15f-0b45-9324-5ad6fe0fa705",
    "lease_id":  "",
    "renewable":  false,
    "lease_duration":  0,
    "data":  {
                 "zip":  "zap"
             },
    "wrap_info":  null,
    "warnings":  null,
    "auth":  null
}
```

NOTE: Wrapped data can only be retrieved once. If the same command were to be executed again, it would fail.

### Generate Random Bytes In Hex

```powershell
PS> Get-VaultRandomBytes -Bytes 64 -Format Hex -OutputType PSObject -JustData

random_bytes
------------
8d5ca831b51d1d9e7dd9af615a520a3e34d66d47f21e0bd9811c36029c540621b2dd79be5d37dfee8353e4797052330c5412997cebc61566eb56f49bd3eac4f4
```

## Administrative Examples

### Protect (Seal) Vault

```powershell
PS> Protect-Vault

Sealed Active Vault Node: https://devvault01.domain.com:443
```

This command does not require any parameters. When executed, the active Vault node will be sealed. From the API, only the active node can be sealed. You cannot seal a standby node until it becomes active. 

### Unprotect (Unseal) Vault

```powershell
PS> Unprotect-Vault -VaultNode devvault02.domain.com
Please provide a single Unseal Key: ********************************************

type          : shamir
initialized   : True
sealed        : True
t             : 3
n             : 5
progress      : 1
nonce         : daf67ca4-42cb-2970-8891-a6567df6349b
version       : 1.1.2
migration     : False
recovery_seal : False
```

Unprotect-Vault requires a VaultNode, which is populated from the global variable `VAULT_NODES`. You have to specify a node because consul stops advertising DNS for a node that is sealed. 

Additionally, rather than specifying the unseal key as a parameter, it is specified at runtime to prevent writing the key to PSReadline history, or a PSTranscript.

Finally, this command must be executed X times (with different unseal keys), where X is the value of `threshold` or `t` specified in `Get-VaultStatus` or the output of `Unprotect-Vault`, respectively.

### Revoke the Active Vault Leader (Stepdown)

```powershell
PS> Revoke-VaultLeader

Initiated Step-Down on Active Node: https://devvault02.domain.com:443
```

This command requires no input, as it can only be executed against the active node. It causes the active node to step-down, resulting in standby node becoming active. 


# Wrapping Token For DSC Proof-of-Concept

In a Role/Site/AllNodes Configuration, create a wrapping token:

```powershell
$wrappingToken = $(New-VaultWrappedToken -WrapTimeToLive "25h" -WrapPolicies "log-rotation" -JustWrapInfo).token
```

Provide the following attributes to the `New-VaultWrappedToken`:
* A `TimeToLive` value in the format of either seconds (30s), minutes (30m) or hours (30h). Keep in mind that the token's lifespan should not excessively exceed the amount of time it would take for the initial token to be unwrapped. This is to say, if you have a scheduled task that runs every 30 minutes. A reasonable TTL would be `1h`, which give the scheduled task ample time to acquire a more permanent token. This is predicated on deploying the MOF in a timely fashion.
* An array of `policies` that the wrapping token will inherit. These policies need to exist and are defined in the `ACL Policies` tab. Do not give a token more rights than it needs.


Next, create a `File` DSC Resource, whereby the `$wrappingToken` is written to disk:

```powershell
File "LogRotationWrappingToken" {
    DestinationPath = "C:\Windows\Temp\LogRotationWrappingToken.txt" 
    Ensure          = 'Present'
    Type            = 'File'
    Contents        = $wrappingToken
}
```

The one-time use token will be retrieved from disk and used by some scheduled task, process or service to acquire a more permanent (renewable) token to use to authenticate to Hashicorp Vault. Consider the following code block, which might be used in a scheduled task to retrieve the initial wrapping token from disk, and use it to acquire a renewable token with rights to perform an action (in this case, rotating the Vault Audit Log):

```powershell
New-EventLog -LogName Application -Source "HashicorpVault-LogRotation" -ErrorAction SilentlyContinue


[String] $TemporaryTokenLocation = "C:\Windows\Temp\LogRotationWrappingToken.txt"

$global:VAULT_ADDR = 'http://127.0.0.1:8200'

$wrappedToken = Get-VaultWrapping -Token (Get-Content $TemporaryTokenLocation) -IsWrappingToken -ErrorAction 'SilentlyContinue'


Try {
    $existingToken = Get-StoredCredential -Target "LogRotationToken" -AsCredentialObject -ErrorAction 'Stop' |
        Select-Object -ExpandProperty Password

    $global:VAULT_TOKEN = $existingToken
}
Catch {
    Write-EventLog `
        -LogName Application `
        -Source "HashicorpVault-LogRotation" `
        -EntryType Information `
        -EventID 300 `
        -Message "A renewable token could not be retrieved from the CredentialManager. This does not necessarily indicate an issue if this is the first time the scheduled task is being executed."

    $existingToken = $null
}

if ($existingToken) {
    Try {
        $existingToken = Get-VaultToken -Self -ErrorAction 'Stop'
    }
    Catch {
        Write-EventLog `
            -LogName Application `
            -Source "HashicorpVault-LogRotation" `
            -EntryType Warning `
            -EventID 202 `
            -Message "The renewable token in the CredentialManager has expired or otherwise cannot authenticate to Vault."

        $existingToken      = $null
        $global:VAULT_TOKEN = $null
    }
}
else {
    Write-EventLog `
        -LogName Application `
        -Source "HashicorpVault-LogRotation" `
        -EntryType Information `
        -EventID 302 `
        -Message "No permanent token was detected in the CredentialManager."  
}

switch ($true) {
    ($wrappedToken -and $existingToken) {
        #New wrapped token & existing token; Overwrite existing token with newly wrapped token.
        Write-Verbose "Case1 - New wrapped token & existing token; Overwrite existing token with newly wrapped token." -Verbose

        $newStoredCredParams = @{
            Target   = 'LogRotationToken'
            Username = 'N\A'
            Password = $($wrappedToken.auth.client_token)
            Type     = 'Generic'
            Comment  = 'Hashicorp Vault Token for Log Rotation'
            Persist  = 'LocalMachine'
        }

        #Overwrite the existing entry.
        New-StoredCredential @newStoredCredParams

        $global:VAULT_TOKEN = $($wrappedToken.auth.client_token)

        break
    }

    ((-not $wrappedToken) -and $existingToken) {
        #Wrapped token has already been retrieved once & existing token; Renew the existing token.
        Write-Verbose "Case2 - Wrapped token has already been retrieved once & existing token; Renew the existing token." -Verbose

        $renewedToken = $existingToken | Update-VaultToken -Increment 25h | Get-VaultToken

        if ($renewedToken.data.ttl -lt 89000) {
            Write-EventLog `
                -LogName Application `
                -Source "HashicorpVault-LogRotation" `
                -EntryType Warning `
                -EventID 201 `
                -Message "Token renewal failed. The token may have expired or will expire before the next execution of this job. Regenerate and deploy a MOF file for this node to generate a new wrapped token."
        }
        else {
            Write-EventLog `
                -LogName Application `
                -Source "HashicorpVault-LogRotation" `
                -EntryType Information `
                -EventID 305 `
                -Message "Token renewal succeeded."
        }

        break
    }

    ($wrappedToken -and (-not $existingToken)) {
        #New wrapped token & no existing token; Add the wrapped token to the CredentialManager Vault.
        Write-Verbose "Case3 - New wrapped token & no existing token; Add the wrapped token to the CredentialManager Vault." -Verbose

        $newStoredCredParams = @{
            Target   = 'LogRotationToken'
            Username = 'N\A'
            Password = $($wrappedToken.auth.client_token)
            Type     = 'Generic'
            Comment  = 'Hashicorp Vault Token for Log Rotation'
            Persist  = 'LocalMachine'
        }

        New-StoredCredential @newStoredCredParams

        $global:VAULT_TOKEN = $($wrappedToken.auth.client_token)

        break
    }

    ((-not $wrappedToken) -and (-not $existingToken)) {
        #One-time use token has been tampered with and existing token is expired. Report tampering. Processing cannot continue.
        Write-Verbose "Case4 - One-time use token has been tampered with and existing token is expired. Report tampering. Processing cannot continue." -Verbose
        
        Write-EventLog `
            -LogName Application `
            -Source "HashicorpVault-LogRotation" `
            -EntryType Error `
            -EventID 101 `
            -Message "The response wrapping token has been tampered with (or has expired), and the renewable token has also expired. The wrapping token may have been compromised."
        
        return
    }
}

#Get Token Again
Try {
    $existingToken = Get-StoredCredential -Target "LogRotationToken" -AsCredentialObject -ErrorAction 'Stop' |
        Select-Object -ExpandProperty Password

    $env:VAULT_TOKEN = $existingToken
}
Catch {
    Write-EventLog `
        -LogName Application `
        -Source "HashicorpVault-LogRotation" `
        -EntryType Error `
        -EventID 102 `
        -Message "The Vault token stored in the CredentialManager could not be re-retrieved. The audit log will not be rotated."

    return
}


#Sample code post-token-renewal:

#env:VAULT_ADDR and env:VAULT_TOKEN were set above and are implicitly used below...

vault.exe audit disable file
Start-Sleep 1
vault.exe audit enable file file_path=\\server.domain.tld\share\vault_audit_logs\log_2019-07-11.log

```

In this example:
1. Although not explicitly shown, this example relies on and imports the `CredentialManager` module.
2. We define a `TemporaryTokenLocation` and a `VAULT_ADDR` and then use the temporary token to retrieve the wrapped token.
3. We attempt to get an existing renewable token from the CredentialManager and then check that it is valid (not expired) in Vault. We assign that value, if it exists, to `$global:VAULT_TOKEN`.
4. We switch on TRUE over four cases:
    1. Case where the wrapping token is valid and an existing token lives in the credential manager. In this scenario we overwrite the new unwrapped token with the one that lives in the CredentialManager.
    2. Case where the wrapped token has already been retrieved once and an existing token already exists. In this scenario we attempt to renew the existing token. Conditional logic exists to report a failure if the token cannot be renewed.
    3. Case where the wrapping token is valid and there is no existing token in the CredentialManager; In this scenario we add the wrapped token to the CredentialManager Vault.
    4. Case where the wrapping token is invalid (has been used) and there is no valid, existing token in the CredentialManager. In this scenario the token may have been tampered with. Logic can be written to alert on this scenario.
5. Provided that we've hit cases 1, 2 or 3, we can proceed to re-acquire the new/renewed "permanent" token from the CredentialManager. 
6. We then use the token to disable and re-enable the Vault Audit Log Device "File".