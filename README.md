## Synopsis
VaultUtils is a module for interacting with Hashicorp Vault.

## Author
Ben Small <bsmall@wayfair.com>

## Verb Mapping // Command Aliases

Hashicorp Vault uses several "verbs", which, according to PowerShell standards are considered unapproved, and make commands less discoverable. 

Consider the possibility that someone who is familiar with Vault, but not PowerShell might intuit certain commands based on Vault nomenclature. 
The following verb mappings and command alises might actually make a person who is familiar with Vault, but not familiar with Powershell more discoverable:

### Wraping Verbs & Command Aliases

* Wrap --> New
* Unwrap --> Get
* Rewrap --> Update
* Lookup --> Show

<br>

* New-VaultWrapping --> Wrap-VaultWrapping
* Get-VaultWrapping --> Unwrap-VaultWrapping
* Update-VaultWrapping --> Rewrap-VaultWrapping
* Show-VaultWrapping --> Lookup-VaultWrapping

### Seal / Unseal / Stepdown Verbs & Command Aliases

* Seal --> Protect
* Unseal --> Unprotect
* Stepdown --> Revoke

<br>

* Protect-Vault --> Seal-Vault
* Unprotect-Vault --> Unseal-Vault
* Revoke-VaultLeader --> Stepdown-VaultLeader


## Command Usage

### Setting Up Vault Variables

Before you can run most commands, you need to set some global variables:

```
$cred = Get-Credential 

Set-VaultSessionVariable -VaultURL https://hvault.devcorp.wayfair.com -Credential $cred -LoginMethod LDAP
```

You can see all of the variables that get set when you execute this command by running:

```
Get-VaultSessionVariable

Name                           Value
----                           -----
VAULT_ADDR                     https://active.vault.service.consul.devcorp.wayfair.com
VAULT_ADDR_STANDBY             https://standby.vault.service.consul.devcorp.wayfair.com
VAULT_CRED                     System.Management.Automation.PSCredential
VAULT_LOGIN_METHOD             LDAP
VAULT_NODES                    {devbo1chvault02.devcorp.wayfair.com, devbo1chvault01.devcorp.wayfair.com}
```

### Getting the Status of Vault

With `VAULT_ADDR` defined, we can now poll the status of Vault:

```
Get-VaultStatus

seal_type       : shamir
initialized     : True
sealed          : False
total_shares    : 5
threshold       : 3
version         : 1.1.2
cluster_name    : vault-cluster-47802c8f
cluster_id      : 9708a39d-dd9c-017f-333a-5551e83d9be7
cluster_leader  : https://DEVBO1CHVAULT02.devcorp.wayfair.com:443
server_time_utc : 7/1/2019 2:17:53 PM +00:00
ha_enabled      : True
```

Beyond that, we can't do much else though, because we need a `VAULT_TOKEN` to perform authenticated actions...

### Getting A Vault Token For Authentication

The next pair of commands to execute, to complete to "setup" process is:

```
Get-VaultToken | Set-VaultToken
```

Doing so will create another global variable `VAULT_TOKEN`, which will be used to authenticate you to Hashicorp Vault instance defined in `VAULT_ADDR`.

You are now "authenticated" to Vault. From here, you can:
* Create/Read KV secrets your token has access to. 
* Read/Update KV secret engine
* Wrap, unwrap and/or rewrap data, as well as lookup wrapped data information.
* Generate random byte information in Base64 or Hex formats.
* Generate SHA2 hashes for Base64 or Hex-encoded information.

If your token has administrative capabilities, you can seal vault, or tell the active node to step down. 


## Other Code Samples

### Getting a KV Secret

```
Get-VaultKVSecret -Engine dsc -SecretsPath sql_ag/conf_ag -OutputType PSObject -JustData

foo
---
bar
```

### Wrapping KV Information

```
New-VaultWrapping -WrapData @{'zip'='zap'} -WrapTTL 5h -OutputType PSObject

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

```
Show-VaultWrapping -Token s.6z8pEEAxFqaQ91HiVcWNMmVC

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

```
Get-VaultWrapping -Token s.6z8pEEAxFqaQ91HiVcWNMmVC -OutputType Json
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

```
Get-VaultRandomBytes -Bytes 64 -Format Hex -OutputType PSObject -JustData

random_bytes
------------
8d5ca831b51d1d9e7dd9af615a520a3e34d66d47f21e0bd9811c36029c540621b2dd79be5d37dfee8353e4797052330c5412997cebc61566eb56f49bd3eac4f4
```

## Administrative Examples

### Protect (Seal) Vault

```
Protect-Vault

Sealed Active Vault Node: https://DEVBO1CHVAULT01.devcorp.wayfair.com:443
```

This command does not require any parameters. When executed, the active Vault node will be sealed. From the API, only the active node can be sealed. You cannot seal a standby node until it becomes active. 

### Unprotect (Unseal) Vault

```
Unprotect-Vault -VaultNode devbo1chvault02.devcorp.wayfair.com
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

```
Revoke-VaultLeader

Initiated Step-Down on Active Node: https://DEVBO1CHVAULT02.devcorp.wayfair.com:443
```

This command requires no input, as it can only be executed against the active node. It causes the active node to step-down, resulting in standby node becoming active. 