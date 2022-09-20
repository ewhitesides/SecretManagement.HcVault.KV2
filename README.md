# SecretManagement.HcVault.KV2

hashicorp vault kv2 extension for powershell credential manager module

## Setup

### install Powershell SecretManagement module and this module

```pwsh
Install-Module Microsoft.PowerShell.SecretManagement
Install-Module SecretManagement.HcVault.KV2
```

## Usage Examples

### Register Vault with local token file

the following would be used if you want to use a token based authentication

before running the following, set a token in a file somewhere on your system

```pwsh
$Params = @{
    Name   = 'myvault'
    Module = 'SecretManagement.HcVault.KV2'
    VaultParameters = @{
        Server         = 'http://127.0.0.1:8200'
        ApiVersion     = '/v1'
        Kv2Mount       = '/secret'
        AuthType       = 'Token'
        TokenRenewable = $false #set to true if token is renewable
        TokenCachePath = "$env:USERPROFILE\myvault\.vault-token"
    }
    AllowClobber = $true #if you want to overwrite existing vault registration
}
Register-SecretVault @Params
```

### Register Vault with ldap auth

the following would be used for ldap based authentication.

when the token expires it will attempt to use the ldap credentials to set a fresh token

set a path for the cached token

set a credential file on your system with ldap credentials:

```pwsh
$Cred = Get-Credential
$Cred | Export-Clixml -Path "$env:USERPROFILE\myvault\ldapcred.dat"
```

then:

```pwsh
$Params = @{
    Name   = 'myvault'
    Module = 'SecretManagement.HcVault.KV2'
    VaultParameters = @{
        Server         = 'http://127.0.0.1:8200'
        ApiVersion     = '/v1'
        Kv2Mount       = '/secret'
        AuthType       = 'Token'
        TokenRenewable = $false #set to true if token is renewable
        TokenCachePath = "$env:USERPROFILE\myvault\.vault-token"
        LdapCredPath   = "$env:USERPROFILE\myvault\ldapcred.dat
    }
    AllowClobber = $true #if you want to overwrite existing vault registration
}
Register-SecretVault @Params
```

### Get-Secret

example of getting secret stored at <http://127.0.0.1:8200/v1/secret/creds/mypass>

```pwsh
PS /> Get-Secret -Vault 'myvault' -Name '/creds/mypass'
Getting secret /creds/mypass from vault myvault #info stream, not part of output
System.Security.SecureString
```

```pwsh
PS /> Get-Secret -Vault 'myvault' -Name '/creds/mypass' -AsPlainText
Getting secret /creds/mypass from vault myvault
mysecret
```

example of getting hashtable of everything stored at <http://127.0.0.1:8200/v1/secret/creds>

```pwsh
PS /> Get-Secret -Vault 'myvault' -Name '/creds/*'
Getting secret /creds/* from vault myvault

Name                           Value
----                           -----
mypass                         System.Security.SecureString
```

```pwsh
PS /> Get-Secret -Vault 'myvault' -Name '/creds/*' -AsPlainText
Getting secret /creds/* from vault myvault

Name                           Value
----                           -----
mypass                         mysecret
```

### Get-SecretInfo

example of getting secret info (metadata) for all secrets at path <http://127.0.0.1:8200/v1/secret>

```pwsh
PS /> Get-SecretInfo -Vault 'myvault' -Name '*'
Getting secret info * from vault myvault

Name    Type      VaultName
----    ----      ---------
/creds  Hashtable myvault
/creds2 Hashtable myvault
```

example of getting secret info (metadata) for specific path <http://127.0.0.1:8200/v1/secret/creds>

```pwsh
PS /> Get-SecretInfo -Vault 'myvault' -Name '/creds'
Getting secret info /creds from vault myvault

Name   Type      VaultName
----   ----      ---------
/creds Hashtable myvault
```

additional metadata properties are output, but are hidden from the default view.
they can be viewed with Format-List:

```pwsh
PS /> Get-SecretInfo -Vault 'myvault' -Name '/creds' | fl *
Getting secret info /creds from vault myvault

Name      : /creds
Type      : Hashtable
VaultName : myvault
Metadata  : {[cas_required, False], [created_time, 2022-09-20T14:32:48.288957134Z], [current_version, 1], [custom_metadata, ]…}
```

### Set-Secret

example of setting a hashtable stored at <http://127.0.0.1:8200/v1/secret/creds>

```pwsh
PS /> Set-Secret -Vault 'myvault' -Name '/creds' -Secret @{'mypass'='mysecret'}
```

example of setting a PSCredential secret stored at <http://127.0.0.1:8200/v1/secret/creds>

```pwsh
PS /> $secret = [System.Management.Automation.PSCredential]::new(
    'mypass',
    (ConvertTo-SecureString -String 'mysecret' -AsPlainText -Force)
)
PS /> Set-Secret -Vault 'myvault' -Name '/creds' -Secret $secret
```

### Remove-Secret

example of removing a secret(s) stored at <http://127.0.0.1:8200/v1/secret/creds>

```pwsh
PS /> Remove-Secret -Vault 'myvault' -Name '/creds'
```

### Test-SecretVault

need to implement/add info here

## Development Info

the code is currently being developed/tested with hashicorp vault version 1.11.0

the following assumes you have docker desktop and vscode installed on your machine

```bash
clone code
open code with 'devcontainer open .'
```

pester tests are designed should be run from developement container, with cwd set to Test:

```bash
cd Test
invoke-pester -tagfilter 'unit'
```

unit tests are run from the perspective of the custom extension module

integration tests are run from the perspective of the parent SecretManagement module

## TODO

- add examples of registering with ldap auth
- implement Test-SecretVault
- implement Set-SecretInfo
- implement Set-Secret -Metadata (using Set-SecretInfo)
- add simple ldap server into the container so we can test ldap auth
