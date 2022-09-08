#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.3.3'}
#Requires -Modules @{ModuleName='Microsoft.PowerShell.SecretManagement';ModuleVersion='1.1.2'}

#Supress the following PSScriptAnalyzer warnings
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
Param()

Describe 'Remove-Secret' -Tag 'Unit' {
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
    BeforeEach {
        #set a test secret with vault cli
        Invoke-Expression "vault kv put -mount=$VaultMount $VaultPath $VaultKey=$VaultVal"
    }
    AfterAll {
        #remove cache file and dir
        Remove-Item -Path $CacheDir -Recurse -Force

        #remove secrets at path $VaultPath
        Invoke-Expression "vault kv metadata delete -mount=$VaultMount $VaultPath"

        #remove module from memory
        Remove-Module -Name $NestedModuleName
    }

    It 'should have a secret to verify no false positives' {
        Invoke-Expression "vault kv get -mount=$VaultMount -field=$VaultKey $VaultPath" |
        Should -Be $VaultVal
    }

    It 'should remove a secret and return nothing' {
        Remove-ExtSecret @Params -Name "/$VaultPath" | Should -BeNullOrEmpty
    }

    It 'should remove a secret' {
        Remove-ExtSecret @Params -Name "/$VaultPath"
        $cmd = "vault kv get -mount=$VaultMount -field=$VaultKey $VaultPath"
        Invoke-Expression ". { $cmd } *>&1" | Should -Be "No data found at $VaultMount/data/$VaultPath"
    }
}

Describe 'Remove-Secret' -Tag 'Integration' {
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
    BeforeEach {
        #set a test secret with vault cli
        Invoke-Expression "vault kv put -mount=$VaultMount $VaultPath $VaultKey=$VaultVal"
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

    It 'should have a secret to verify no false positives' {
        Invoke-Expression "vault kv get -mount=$VaultMount -field=$VaultKey $VaultPath" |
        Should -Be $VaultVal
    }

    It 'should remove a secret and return nothing' {
        Remove-Secret -Name "/$VaultPath" -Vault $VaultName |
        Should -BeNullOrEmpty
    }

    It 'should remove a secret' {
        Remove-Secret -Name "/$VaultPath" -Vault $VaultName
        $cmd = "vault kv get -mount=$VaultMount -field=$VaultKey $VaultPath"
        Invoke-Expression ". { $cmd } *>&1" | Should -Be "No data found at $VaultMount/data/$VaultPath"
    }
}