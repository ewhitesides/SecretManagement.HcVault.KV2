@{
    ModuleVersion     = '0.0.0.1'
    Author            = 'Erik Whitesides'
    Description       = 'SecretManagement extension for Hashicorp Vault KV2 Engine'
    NestedModules     = @('./SecretManagement.HcVault.KV2.Extension')
    FunctionsToExport = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('SecretManagement')
            LicenseUri = 'https://mit-license.org/'
        }
        ReleaseNotes = @"
0.0.0.1
    initial
"@
    }
}
