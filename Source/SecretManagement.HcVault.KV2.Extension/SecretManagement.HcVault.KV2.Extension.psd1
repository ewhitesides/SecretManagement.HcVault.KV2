@{
    ModuleVersion     = '0.0.1'
    RootModule        = './SecretManagement.HcVault.KV2.Extension.psm1'
    FunctionsToExport = @(
        'Get-Secret',
        'Set-Secret',
        'Remove-Secret',
        'Get-SecretInfo',
        'Test-SecretVault'
    )
}

