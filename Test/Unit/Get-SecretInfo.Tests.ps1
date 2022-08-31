#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.3.3'}
#Requires -Modules @{ModuleName='Microsoft.PowerShell.SecretManagement';ModuleVersion='1.1.2'}

Describe 'Get-SecretInfo' -Tag 'Unit' {
    BeforeAll {
        #import parent module because it contains some types that we need for testing
        Import-Module 'Microsoft.PowerShell.SecretManagement'

        #Import Get-SecretInfo as Get-ExtSecretInfo from the Extension's Nested Module,
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
                Kv2Path        = "/$VaultPath"
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

    It 'should get the secret info successfully' {
        Get-ExtSecretInfo -Name '/*' @Params |
        Should -Be 'mysecret'
    }
}