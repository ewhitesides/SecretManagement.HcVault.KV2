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

set a token in a file somewhere on your system,
for example $env:USERPROFILE/myvault/.vault-token

```pwsh
$AdditionalParameters = @{
    Server         = 'http://127.0.0.1:8200
    ApiVersion     = '/v1'
    Kv2Mount       = '/secret'
    AuthType       = 'Token'
    TokenRenewable = $false #set to true if token is renewable
    TokenCachePath = "$env:USERPROFILE/myvault/.vault-token"
}

Register-SecretVault -Name 'myvault' -Module 'SecretManagement.HcVault.KV2'
```

### Get-Secret

example of accessing a secret stored at 'http://127.0.0.1:8200/v1/secret/myapp/user1'

```pwsh
Get-Secret -Vault 'myvault' -Name '/myapp/user1' -AsPlainText
```

example of getting a hashtable of all stored at 'http://127.0.0.1:8200/v1/secret/myapp'

```pwsh
Get-Secret -Vault 'myvault' -Name '/myapp/*' -AsPlainText
```

### Get-SecretInfo

add info here

### Set-Secret

add info here

### Remove-Secret

add info here

### Test-SecretVault

add info here

### Register the vault

if for example your are currently doing the following with the vault cli:

```bash
vault login -method=ldap username=<user>
vault kv get -mount=secret -field=mykey mypath/to/keys
```

then you should first set a credential file

```pwsh
$a = Get-Credential
$a | Export-Clixml -Path 'C:\mycred.dat'
```

then you would want to register the vault as:

```pwsh
$RegisterParams = @{
    Name            = 'myvault'
    Module          = 'SecretManagement.HcVault.KV2'
    VaultParameters = @{
        Server         = 'https://myvault.com'
        ApiVersion     = '/v1'
        Kv2Mount       = '/secret'
        AuthType       = 'LDAP'
        TokenRenewable = $true
        TokenCachePath = 'C:\myvault\.vault-token'
        LdapCredPath   = 'C:\mycred.dat'
    }
    AllowClobber     = $true
}
Register-SecretVault @RegisterParams
```

and get the value for key 'mykey' with:

```pwsh
Get-Secret -Vault 'myvault' -Name '/mypath/to/keys/mykey' -AsPlainText
```

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

- update README for Get-Secret
- update README for Get-SecretInfo
- update README for Set-Secret
- implement Set-SecretInfo
- implement Set-Secret -Metadata (using Set-SecretInfo)
- add code for metadata parameter in Set-Secret
- add tests for metadata parameter in Set-Secret
- add simple ldap server into the container so we can test ldap auth
