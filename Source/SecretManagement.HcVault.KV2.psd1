@{
    ModuleVersion     = '0.0.0.3'
    GUID              = 'd0cb5f62-eed0-4577-91f2-ae4de5d9fde1'
    Author            = 'Erik Whitesides'
    Description       = 'SecretManagement extension for Hashicorp Vault KV2 Engine'
    NestedModules     = @('./SecretManagement.HcVault.KV2.Extension')
    FunctionsToExport = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('SecretManagement')
            ProjectUri = 'https://github.com/ewhitesides/SecretManagement.HcVault.KV2'
        }
        ReleaseNotes = @"
0.0.0.3
    fix to Get-SecretInfo Name parameter
0.0.0.2
    add project uri
0.0.0.1
    initial
"@
    }
}
