#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.3.3'}
#Requires -Modules @{ModuleName='Microsoft.PowerShell.SecretManagement';ModuleVersion='1.1.2'}

Describe 'Get-SecretInfo' -Tag 'Unit' {
    BeforeAll {
        #import parent module - some of tests and Get-ExtSecretInfo require its classes
        $ParentModuleName = 'Microsoft.PowerShell.SecretManagement'
        Import-Module -Name $ParentModuleName

        #Import Get-SecretInfo as Get-ExtSecretInfo from the Extension's Nested Module,
        #to avoid confusion with Get-Secret from Microsoft.PowerShell.SecretManagement
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
        $VaultName        = 'pestertestvault'
        $VaultMount       = 'secret'
        $Script:VaultPath = 'creds'
        $Script:VaultKey  = 'mypass'
        $VaultVal         = 'mysecret'
        $CacheDir         = "$env:HOME/$VaultName"
        $CacheFilePath    = "$env:HOME/$VaultName/.vault-token"

        #set token
        New-Item -ItemType 'Directory' -Path $CacheDir -Force | Out-Null
        Set-Content -Path $CacheFilePath -Value $env:VAULT_TOKEN

        #set a test secret with vault cli
        Invoke-Expression "vault kv put -mount=$VaultMount $VaultPath $VaultKey=$VaultVal"

        #set parameters that are fed to Get-ExtSecret function
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
        $Script:Output = Get-ExtSecretInfo -Name '*' @Params
    }
    AfterAll {
        #remove cache file and dir
        Remove-Item -Path $CacheDir -Recurse -Force

        #remove secrets at path creds
        Invoke-Expression "vault kv metadata delete -mount=$VaultMount $VaultPath"

        #remove modules from memory
        Remove-Module -Name $NestedModuleName
        Remove-Module -Name $ParentModuleName
    }

    It 'should return objects of type SecretInformation' {
        $Output -is [Microsoft.PowerShell.SecretManagement.SecretInformation] |
        Should -Be $true
    }

    It 'should return correct Name' {
        $Output.Name | Should -Be "/$VaultPath/$VaultKey"
    }

    It 'should return correct Type' {
        $Output.Type | Should -Be 'String'
    }

    It 'should return correct VaultName' {
        $Output.VaultName | Should -Be $VaultName
    }

    It 'should return a Metadata.created_time property' {
        $Output.Metadata.created_time |
        Should -Be -Not NullOrEmpty
    }
}

Describe 'Get-SecretInfo' -Tag 'Integration' {
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

        $Script:Output = Get-SecretInfo -Name '*'
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

    It 'should return objects of type SecretInformation' {
        $Output -is [Microsoft.PowerShell.SecretManagement.SecretInformation] |
        Should -Be $true
    }

    It 'should return correct Name' {
        $Output.Name | Should -Be "/$VaultPath/$VaultKey"
    }

    It 'should return correct Type' {
        $Output.Type | Should -Be 'string'
    }

    It 'should return correct VaultName' {
        $Output.VaultName | Should -Be $VaultName
    }

    It 'should return a Metadata.created_time property' {
        $Output.Metadata.created_time |
        Should -Be -Not NullOrEmpty
    }
}
