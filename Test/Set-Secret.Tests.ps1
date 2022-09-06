#Requires -Modules @{ModuleName='Pester';ModuleVersion='5.3.3'}
#Requires -Modules @{ModuleName='Microsoft.PowerShell.SecretManagement';ModuleVersion='1.1.2'}

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
        $VaultName        = 'pestertestvault'
        $VaultMount       = 'secret'
        $Script:VaultPath = 'creds'
        $Script:VaultKey  = 'mypass'
        $Script:VaultVal  = 'mysecret'
        $CacheDir         = "$env:HOME/$VaultName"
        $CacheFilePath    = "$env:HOME/$VaultName/.vault-token"

        #set token
        New-Item -ItemType 'Directory' -Path $CacheDir -Force | Out-Null
        Set-Content -Path $CacheFilePath -Value $env:VAULT_TOKEN

        #set parameters for Set-ExtSecret
        $Script:Params = @{
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