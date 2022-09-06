#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.3.3'}

Describe 'Get-Secret' -Tag 'Unit' {
    BeforeAll {
        #Import Get-Secret as Get-ExtSecret from the Extension's Nested Module,
        #to avoid confusion with Get-Secret from Microsoft.PowerShell.SecretManagement
        $NestedModuleName = (
            Get-ChildItem -Path '../../Source' |
            Where-Object {$_.Name -match 'Extension$'}
        ).Name
        $IpmoParams = @{
            Name   = "../../Source/$NestedModuleName/$NestedModuleName.psd1"
            Prefix = 'Ext'
        }
        Import-Module @IpmoParams

        #set vault env variables for vault cli
        $VaultFile = '../.vault.json'
        $VaultJson = Get-Content -Path $VaultFile | ConvertFrom-Json
        $env:VAULT_ADDR  = $VaultJson.VAULT_ADDR
        $env:VAULT_TOKEN = $VaultJson.VAULT_TOKEN

        #vault vars
        $VaultName     = 'pestertestvault'
        $VaultMount    = 'secret'
        $VaultPath     = 'creds'
        $VaultKey      = 'mypass'
        $VaultVal      = 'mysecret'
        $CacheDir      = "$env:HOME/$VaultName"
        $CacheFilePath = "$env:HOME/$VaultName/.vault-token"

        #set token
        New-Item -ItemType 'Directory' -Path $CacheDir -Force | Out-Null
        Set-Content -Path $CacheFilePath -Value $env:VAULT_TOKEN

        #set a test secret with vault cli
        Invoke-Expression "vault kv put -mount=$VaultMount $VaultPath $VaultKey=$VaultVal"

        #set parameters that are fed to Get-ExtSecret function
        $Script:Params = @{
            VaultName = $VaultName
            AdditionalParameters = @{
                Server         = $env:VAULT_ADDR
                ApiVersion     = '/v1'
                Kv2Mount       = "/$VaultMount"
                AuthType       = 'Token'
                TokenRenewable = $false #root token not renewable need to make test with another
                TokenCachePath = $CacheFilePath
            }
        }
    }
    AfterAll {
        #remove cache file and dir
        Remove-Item -Path $CacheDir -Recurse -Force

        #remove secrets at path creds
        Invoke-Expression "vault kv metadata delete -mount=$VaultMount $VaultPath"
    }

    It 'should get the field value when Name parameter ends with the field key' {
        Get-ExtSecret -Name "/$VaultPath/$VaultKey" @Params |
        Should -Be $VaultVal
    }

    It 'should return parseable json when Name parameter ends with an asterisk' {
        Get-ExtSecret -Name "/$VaultPath/*" @Params |
        ConvertFrom-Json |
        Select-Object -ExpandProperty $VaultKey |
        Should -Be $VaultVal
    }
}