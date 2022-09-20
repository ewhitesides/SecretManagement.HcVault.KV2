function Get-SecretInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Alias('Name')]
        [string]$Filter,

        [Parameter(Mandatory)]
        [Alias('Vault')]
        [string]$VaultName,

        [Parameter(Mandatory)]
        [Alias('VaultParameters')]
        [hashtable]$AdditionalParameters
    )

    #stop on all non-terminating errors in addition to terminating
    $ErrorActionPreference = 'Stop'

    #message
    Write-Information "Getting secret info $Filter from vault $VaultName"

    #set AdditionalParameters to shorter variable to stay within 80 column
    $AP = $AdditionalParameters

    #Validate AdditionalParameters
    Test-VaultParameters $AP

    #Construct uri
    $Uri = $AP.Server + $AP.ApiVersion + $AP.Kv2Mount + '/metadata'

    Try {
        #try to get secret info using cached token
        $Token = Get-CachedToken $AP

        New-SecretInfoObj -VaultName $VaultName -Uri $Uri -Token $Token -Depth 0 |
        Where-Object {$_.Name -like $Filter}
    }
    Catch {
        #if it fails, try with a fresh token
        $Token = Get-Token $AP

        New-SecretInfoObj -VaultName $VaultName -Uri $Uri -Token $Token -Depth 0 |
        Where-Object {$_.Name -like $Filter}

        #set the token that succeeded to cache for next use
        Set-CachedToken $AP.TokenCachePath $Token
    }
}
