Describe 'Get-Secret' -Tag 'Unit' {
    BeforeAll {
        #set vault environment variables
        $VaultFile = ".vault.json"
        $VaultJson = Get-Content -Path $VaultFile | ConvertFrom-Json
        $env:VAULT_ADDR  = $VaultJson.VAULT_ADDR
        $env:VAULT_TOKEN = $VaultJson.VAULT_TOKEN

        #set a test secret with the vault cli
        vault kv put -mount=secret creds password=supersecret

        #Symlink our module to module path
        $ModulePath=$env:PSModulePath.Split(':')[0]

        New-Item -ItemType 'SymbolicLink' `
            -Path "$ModulePath/SecretManagement.HcVault.KV2" `
            -Target "/workspaces/SecretManagement.HcVault.KV2/Source"

        #mkdir pester test vault folder
        $CacheDir = (
            New-Item -ItemType 'Directory' -Path "$env:HOME/pestertestvault" -Force
        ).FullName

        #register a test vault
        $RegisterParams = @{
            Name   = 'pestertestvault'
            Module = 'SecretManagement.HcVault.KV2'
            VaultParameters = @{
                Server         = 'http://127.0.0.1:8200'
                ApiVersion     = '/v1'
                Kv2Mount       = '/secret'
                Kv2Path        = '/creds'
                AuthType       = 'Token'
                TokenCachePath = "$CacheDir/.vault-token"
            }
            AllowClobber = $true
        }
        Register-SecretVault @RegisterParams
    }

    It 'given no parameters, vault status should be initialized' {
        $status = vault status -format=json
        ($status | convertfrom-json).initialized | Should -Be 'true'
    }

    AfterAll {
        #unregister vault
        Unregister-SecretVault -Name 'pestertestvault'

        #remove symlink
        remove-item -Path "$ModulePath/SecretManagement.HcVault.KV2"
    }
}