Describe 'Get-Secret' -Tag 'Unit' {
    BeforeAll {
        #set vault environment variables
        $VaultFile = ".vault.json"
        $VaultJson = Get-Content -Path $VaultFile | ConvertFrom-Json
        $env:VAULT_ADDR  = $VaultJson.VAULT_ADDR
        $env:VAULT_TOKEN = $VaultJson.VAULT_TOKEN

        #load the module with Get-Secret
        #Import-Module '../Source/SecretManagement.HcVault.KV2.Extension.psd1'

        #set a test secret with the vault cli
        #vault kv put -mount=secret -field=testcreds mykey=myvalue

        #register a test vault
    }

    It 'given no parameters, vault status should be initialized=true' {
        $status = vault status -format=json
        ($status | convertfrom-json).initialized | Should -Be 'true'
    }
}