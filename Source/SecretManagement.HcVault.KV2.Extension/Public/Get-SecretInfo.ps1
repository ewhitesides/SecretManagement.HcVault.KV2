function Get-SecretInfo {
    [CmdletBinding()]
    param (
        #Filter that is defined however you want to handle it. Recommend wildcards.
        #If this is blank, you should assume the user wants to get all secretinfos in the vault
        #This is passed in from Get-SecretInfo -Name. Note it is named different!
        [Alias('Name')]
        [string]$Filter,

        #The VaultName of the secret, passed through from SecretManagement module
        [Parameter(Mandatory)]
        [Alias('Vault')]
        [string]$VaultName,

        #Passed in from SecretManagement registered VaultParameters.
        [Parameter(Mandatory)]
        [Alias('VaultParameters')]
        [hashtable]$AdditionalParameters = (Get-SecretVault -Name $VaultName).VaultParameters
    )
    Throw "not implemented"
}
