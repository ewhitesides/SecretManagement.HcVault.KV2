function Remove-Secret {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        #Passed in from Remove-Secret -Name
        [Parameter(Mandatory)]
        [string]$Name,

        #The VaultName of the secret, passed through from SecretManagement module
        [Parameter(Mandatory)]
        [Alias('Vault')]
        [string]$VaultName,

        #Passed in from SecretManagement registered VaultParameters
        [Parameter(Mandatory)]
        [Alias('VaultParameters')]
        [hashtable]$AdditionalParameters = (Get-SecretVault -Name $VaultName).VaultParameters
    )
    Throw "not implemented"
}