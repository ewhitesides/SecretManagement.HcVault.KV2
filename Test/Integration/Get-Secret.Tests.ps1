#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.3.3'}
#Requires -Modules @{ModuleName='Microsoft.PowerShell.SecretManagement';ModuleVersion='1.1.2'}

Describe 'Get-Secret' -Tag 'Integration' {
    BeforeAll {
        #module vars
        $ModulePath    = $env:PSModulePath.Split(':')[0]
        $ModuleName    = 'SecretManagement.HcVault.KV2'
        $SymLinkPath   = "$ModulePath/$ModuleName"
        $SymLinkTarget = (Get-Item -Path '../../Source').FullName

        #link our module to module path so
        #Microsoft.PowerShell.SecretManagement module can use it
        New-Item -ItemType 'SymbolicLink' -Path $SymLinkPath -Target $SymLinkTarget

        #set vault env variables for vault cli
        $VaultFile = '../.vault.json'
        $VaultJson = Get-Content -Path $VaultFile | ConvertFrom-Json
        $env:VAULT_ADDR  = $VaultJson.VAULT_ADDR
        $env:VAULT_TOKEN = $VaultJson.VAULT_TOKEN

        #vault vars
        $VaultName       = 'pestertestvault'
        $VaultMount      = 'secret'
        $VaultPath       = 'creds'
        $Script:VaultKey = 'mypass'
        $Script:VaultVal = 'mysecret'
        $CacheDir        = "$env:HOME/$VaultName"
        $CacheFilePath   = "$env:HOME/$VaultName/.vault-token"

        #set token
        New-Item -ItemType 'Directory' -Path $CacheDir -Force | Out-Null
        Set-Content -Path $CacheFilePath -Value $env:VAULT_TOKEN

        #set a test secret with the vault cli
        Invoke-Expression "vault kv put -mount=$VaultMount $VaultPath $VaultKey=$VaultVal"

        #register a test vault
        $RegisterParams = @{
            Name   = $VaultName
            Module = $ModuleName
            VaultParameters = @{
                Server         = $env:VAULT_ADDR
                ApiVersion     = '/v1'
                Kv2Mount       = "/$VaultMount"
                Kv2Path        = "/$VaultPath"
                AuthType       = 'Token'
                TokenRenewable = $false #root token not renewable need to make test with another
                TokenCachePath = $CacheFilePath
            }
            AllowClobber = $true
        }
        Register-SecretVault @RegisterParams
    }
    AfterAll {
        #unregister vault
        Unregister-SecretVault -Name $VaultName

        #remove symlink
        Remove-Item -Path $SymLinkPath

        #remove cache file and dir
        Remove-Item -Path $CacheDir -Recurse -Force

        #remove secrets at path creds
        Invoke-Expression "vault kv metadata delete -mount=$VaultMount $VaultPath"
    }

    It 'given specific key for Name, Get-Secret should return the value' {
        Get-Secret -Vault $VaultName -Name $VaultKey -AsPlainText |
        Should -Be $VaultVal
    }

    It 'given * for Name, Get-Secret should return json string containing value' {
        Get-Secret -Vault $VaultName -Name '*' -AsPlainText |
        ConvertFrom-Json |
        Select-Object -ExpandProperty $VaultKey |
        Should -Be $VaultVal
    }
}