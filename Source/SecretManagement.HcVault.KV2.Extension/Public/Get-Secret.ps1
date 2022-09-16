function Get-Secret {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidatePattern('^/')]
        [string]$Name,

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
    Write-Information "Getting secret $Name from vault $VaultName"

    #set AdditionalParameters to shorter variable to stay within 80 column
    $AP = $AdditionalParameters

    #Validate AdditionalParameters
    Test-VaultParameters $AP

    #Construct uri
    $Field = $Name | Split-Path -Leaf
    $Paths = $Name | Split-Path -Parent
    $Uri = $AP.Server + $AP.ApiVersion + $AP.Kv2Mount + '/data' + $Paths

    Try {
        #try to get data using cached token
        $Token = Get-CachedToken $AP
        $Params = @{
            Uri     = $Uri
            Headers = @{"X-Vault-Token"="$Token"}
        }
        if ($Field -eq '*') {
            (Invoke-RestMethod @Params).data.data |
            ConvertTo-HashTable
        }
        else {
            (Invoke-RestMethod @Params).data.data |
            Select-Object -ExpandProperty $Field
        }
    }
    Catch {
        #if it fails, try with a fresh token
        $Token = Get-Token $AP
        $Params = @{
            Uri = $Uri
            Headers = @{"X-Vault-Token"="$Token"}
        }
        if ($Field -eq '*') {
            (Invoke-RestMethod @Params).data.data |
            ConvertTo-HashTable
        }
        else {
            (Invoke-RestMethod @Params).data.data |
            Select-Object -ExpandProperty $Field
        }

        #set the token that succeeded to cache for next use
        Set-CachedToken $AP.TokenCachePath $Token
    }
}
