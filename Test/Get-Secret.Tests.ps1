#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.3.3'}
#Requires -Modules @{ModuleName='Microsoft.PowerShell.SecretManagement';ModuleVersion='1.1.2'}

#Supress the following PSScriptAnalyzer warnings
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
Param()

Describe 'Get-Secret' -Tag 'Unit' {
    BeforeAll {
        #Import Get-Secret as Get-ExtSecret from the Extension's Nested Module,
        #to avoid confusion with Get-Secret from SecretManagement module
        $NestedModuleName = (
            Get-ChildItem -Path '../Source' |
            Where-Object {$_.Name -match 'Extension$'}
        ).Name
        $IpmoParams = @{
            Name   = "../Source/$NestedModuleName/$NestedModuleName.psd1"
            Prefix = 'Ext'
        }
        Import-Module @IpmoParams

        #set vault env variables for vault cli
        $VaultFile = '.vault.json'
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

        #set parameters for Get-ExtSecret
        $Params = @{
            VaultName            = $VaultName
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

        #remove secrets at path $VaultPath
        Invoke-Expression "vault kv metadata delete -mount=$VaultMount $VaultPath"

        #remove module from memory
        Remove-Module -Name $NestedModuleName
    }

    It 'should return value of type string when Name arg ends with the key' {
        $Output = Get-ExtSecret -Name "/$VaultPath/$VaultKey" @Params
        $Output -is [string] | Should -Be $true
    }

    It 'should get the value when Name arg ends with the key' {
        Get-ExtSecret -Name "/$VaultPath/$VaultKey" @Params |
        Should -Be $VaultVal
    }

    It 'should return value of type hashtable when Name arg ends with asterisk' {
        $Output = Get-ExtSecret -Name "/$VaultPath/*" @Params
        $Output -is [hashtable] | Should -Be $true
    }

    It 'should parse the value when Name arg ends with asterisk' {
        (Get-ExtSecret -Name "/$VaultPath/*" @Params).$VaultKey |
        Should -Be $VaultVal
    }
}

Describe 'Get-Secret' -Tag 'Integration' {
    BeforeAll {
        #add this extension module to modulepath via symbolic link
        #so Microsoft.PowerShell.SecretManagement module can see it
        $ModuleName = (
            Get-ChildItem -Path '../Source' |
            Where-Object {$_.Extension -eq '.psd1'}
        ).BaseName
        $ModulePath    = $env:PSModulePath.Split(':')[0]
        $SymLinkPath   = "$ModulePath/$ModuleName"
        $SymLinkTarget = (Get-Item -Path '../Source').FullName

        New-Item -ItemType 'SymbolicLink' -Path $SymLinkPath -Target $SymLinkTarget

        #set vault env variables for vault cli
        $VaultFile = '.vault.json'
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

        #set a test secret with the vault cli
        Invoke-Expression "vault kv put -mount=$VaultMount $VaultPath $VaultKey=$VaultVal"

        #register a test vault
        $Params = @{
            Name   = $VaultName
            Module = $ModuleName
            VaultParameters = @{
                Server         = $env:VAULT_ADDR
                ApiVersion     = '/v1'
                Kv2Mount       = "/$VaultMount"
                AuthType       = 'Token'
                TokenRenewable = $false #root token not renewable need to make test with another
                TokenCachePath = $CacheFilePath
            }
            AllowClobber = $true
        }
        Register-SecretVault @Params
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

    It 'should return value of type string when Name arg ends with the key' {
        $Output = Get-Secret -Vault $VaultName -Name "/$VaultPath/$VaultKey" -AsPlainText
        $Output -is [string] | Should -Be $true
    }

    It 'should get the value when Name arg ends with the key' {
        Get-Secret -Vault $VaultName -Name "/$VaultPath/$VaultKey" -AsPlainText |
        Should -Be $VaultVal
    }

    It 'should return value of type hashtable when Name arg ends with an asterisk' {
        $Output = Get-Secret -Vault $VaultName -Name "/$VaultPath/*" -AsPlainText
        $Output -is [hashtable] | Should -Be $true
    }

    It 'should parse the value when Name arg ends with asterisk' {
        Get-Secret -Vault $VaultName -Name "/$VaultPath/*" -AsPlainText |
        Select-Object -ExpandProperty $VaultKey |
        Should -Be $VaultVal
    }
}
