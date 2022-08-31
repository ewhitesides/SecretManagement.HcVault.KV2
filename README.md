#get subkeys at this path
#curl --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/subkeys/creds

#get further paths at this path
#curl --request LIST --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/metadata/creds

# PS /workspaces/SecretManagement.HcVault.KV2/Test/Unit> curl --request LIST --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/metadata
# {"request_id":"c5ad60bf-98a4-6850-c0f7-386af81b0c6a","lease_id":"","renewable":false,"lease_duration":0,"data":{"keys":["creds","creds/"]},"wrap_info":null,"warnings":null,"auth":null}
# PS /workspaces/SecretManagement.HcVault.KV2/Test/Unit>
# PS /workspaces/SecretManagement.HcVault.KV2/Test/Unit> curl --request LIST --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/subkeys/creds
# {"errors":["1 error occurred:\n\t* unsupported operation\n\n"]}
# PS /workspaces/SecretManagement.HcVault.KV2/Test/Unit> curl --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/subkeys/creds
# {"request_id":"d6bc1136-f8f7-0199-3462-f2e3c2a70423","lease_id":"","renewable":false,"lease_duration":0,"data":{"metadata":{"created_time":"2022-08-31T02:51:59.365219274Z","custom_metadata":null,"deletion_time":"","destroyed":false,"version":2},"subkeys":{"mypass":null}},"wrap_info":null,"warnings":null,"auth":null}
# PS /workspaces/SecretManagement.HcVault.KV2/Test/Unit> curl --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/subkeys/creds/creds
# {"errors":[]}
# PS /workspaces/SecretManagement.HcVault.KV2/Test/Unit> curl --request LIST --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/metadata/creds/
# {"request_id":"2baac4b3-a915-0e37-c37d-bcf2c4b9c055","lease_id":"","renewable":false,"lease_duration":0,"data":{"keys":["something"]},"wrap_info":null,"warnings":null,"auth":null}

#TODO: Find out why the fully qualified is required on Linux even though using Namespace is defined above


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
