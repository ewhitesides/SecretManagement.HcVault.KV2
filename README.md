# SecretManagement.HcVault.KV2

basic outline of a hashicorp vault extension for powershell credentialmanager module

## Development Setup

the following assumes you have docker desktop and vscode installed on your machine

clone code

open code with 'devcontainer open .'

once loaded, load env vars for test instance of vault with '. $LOCALDEV'

## Usage

### install Powershell SecretManagement module

```pwsh
Install-Module Microsoft.PowerShell.SecretManagement -Scope 'AllUsers' -Force
```

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
        Kv2Mount       = 'secret'
        Kv2Path        = '/mypath/to/keys'
        AuthType       = 'LDAP'
        TokenCachePath = 'C:\.vault-token'
        LdapCredPath   =  'C:\mycred.dat'
    }
    AllowClobber     = $true
}
Register-SecretVault @RegisterParams
```

and get the value for key 'mykey' with:

```pwsh
Get-Secret -Vault 'myvault' -Name 'mykey' -AsPlainText
```

