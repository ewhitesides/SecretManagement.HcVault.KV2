#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.3.3'}
#Requires -Modules @{ModuleName='Microsoft.PowerShell.SecretManagement';ModuleVersion='1.1.2'}

#Supress the following PSScriptAnalyzer warnings
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
Param()

Describe 'Set-Secret' -Tag 'Unit' {
    BeforeAll {
        #Import Set-Secret as Set-ExtSecret from the Extension's Nested Module,
        #to avoid confusion with Set-Secret from SecretManagement module
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

        #set parameters for Set-ExtSecret
        $Params = @{
            Name                 = "/$VaultPath"
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
    AfterEach {
        #remove secrets at path $VaultPath
        Invoke-Expression "vault kv metadata delete -mount=$VaultMount $VaultPath"
    }
    AfterAll {
        #remove cache file and dir
        Remove-Item -Path $CacheDir -Recurse -Force

        #remove module from memory
        Remove-Module -Name $NestedModuleName
    }

    It 'should set a hashtable secret successfully' {
        Set-ExtSecret @Params -Secret @{$VaultKey=$VaultVal}
        Invoke-Expression "vault kv get -mount=$VaultMount -field=$VaultKey $VaultPath" |
        Should -Be $VaultVal
    }

    It 'should set a PSCredential secret successfully' {
        $cred = [System.Management.Automation.PSCredential]::new(
            $VaultKey,
            (ConvertTo-SecureString -String $VaultVal -AsPlainText -Force)
        )
        Set-ExtSecret @Params -Secret $cred
        Invoke-Expression "vault kv get -mount=$VaultMount -field=$VaultKey $VaultPath" |
        Should -Be $VaultVal
    }
}

Describe 'Set-Secret' -Tag 'Integration' {
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
    AfterEach {
        #remove secrets at path $VaultPath
        Invoke-Expression "vault kv metadata delete -mount=$VaultMount $VaultPath"
    }
    AfterAll {
        #unregister vault
        Unregister-SecretVault -Name $VaultName

        #remove symlink
        Remove-Item -Path $SymLinkPath

        #remove cache file and dir
        Remove-Item -Path $CacheDir -Recurse -Force
    }

    It 'should set a hashtable secret successfully' {
        Set-Secret -Vault $VaultName -Name "/$VaultPath" -Secret @{$VaultKey=$VaultVal}
        Invoke-Expression "vault kv get -mount=$VaultMount -field=$VaultKey $VaultPath" |
        Should -Be $VaultVal
    }

    It 'should set a PSCredential secret successfully' {
        $cred = [System.Management.Automation.PSCredential]::new(
            $VaultKey,
            (ConvertTo-SecureString -String $VaultVal -AsPlainText -Force)
        )
        Set-Secret -Vault $VaultName -Name "/$VaultPath" -Secret $cred
        Invoke-Expression "vault kv get -mount=$VaultMount -field=$VaultKey $VaultPath" |
        Should -Be $VaultVal
    }
}