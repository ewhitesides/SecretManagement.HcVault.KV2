function Remove-Secret {
<#
.DESCRIPTION
curl --header "X-Vault-Token: xxx" --request DELETE http://127.0.0.1:8200/v1/secret/data/creds
#>
    param (
        [Parameter(Mandatory)]
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
    $Uri = $AP.Server + $AP.ApiVersion + $AP.Kv2Mount + '/data' + $Name

    Try {
        #try to delete secret using cached token
        $Token = Get-CachedToken $AP
        $Params = @{
            Uri     = $Uri
            Method  = 'Delete'
            Headers = @{"X-Vault-Token" = "$Token"}
        }
        Invoke-RestMethod @Params | Out-Null
    }
    Catch {
        #if it fails, try with a fresh token
        $Token = Get-Token $AP
        $Params = @{
            Uri     = $Uri
            Method  = 'Delete'
            Headers = @{"X-Vault-Token" = "$Token"}
        }
        Invoke-RestMethod @Params | Out-Null

        #set the token taht succeeded to the cache for next use
        Set-CachedToken $AP.TokenCachePath $Token
    }
}
