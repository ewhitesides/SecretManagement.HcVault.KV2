Describe 'TokenAuthFunctions' -Tag 'Integration' {
    BeforeAll {
        #set vault environment variables
        $VaultFile = ".vault.json"
        $VaultJson = Get-Content -Path $VaultFile | ConvertFrom-Json
        $env:VAULT_ADDR  = $VaultJson.VAULT_ADDR
        $env:VAULT_TOKEN = $VaultJson.VAULT_TOKEN

        #pester vars
        $ModulePath    = $env:PSModulePath.Split(':')[0]
        $ModuleName    = 'SecretManagement.HcVault.KV2'
        $SymLinkPath   = "$ModulePath/$ModuleName"
        $SymLinkTarget = (Get-Item -Path '../Source').FullName
        $VaultName     = 'pestertestvault'
        $CacheDir      = "$env:HOME/$VaultName"
        $CacheFilePath = "$env:HOME/$VaultName/.vault-token"

        #link our module to module path so
        #Microsoft.PowerShell.SecretManagement module can use it
        New-Item -ItemType 'SymbolicLink' -Path $SymLinkPath -Target $SymLinkTarget

        #set token
        New-Item -ItemType 'Directory' -Path $CacheDir -Force | Out-Null
        Set-Content -Path $CacheFilePath -Value $env:VAULT_TOKEN

        #set a test secret with the vault cli
        vault kv put -mount=secret creds password=supersecret

        #register a test vault
        $RegisterParams = @{
            Name   = $VaultName
            Module = $ModuleName
            VaultParameters = @{
                Server         = 'http://127.0.0.1:8200'
                ApiVersion     = '/v1'
                Kv2Mount       = '/secret'
                Kv2Path        = '/creds'
                AuthType       = 'Token'
                TokenCachePath = $CacheFilePath
            }
            AllowClobber = $true
        }
        Register-SecretVault @RegisterParams
    }

    It 'given parameter for key, Get-Secret should return the value' {
        Get-Secret -Vault $VaultName -Name 'password' -AsPlainText | Should -Be 'supersecret'
    }

    AfterAll {
        #unregister vault
        Unregister-SecretVault -Name $VaultName

        #remove symlink
        Remove-Item -Path $SymLinkPath
    }
}