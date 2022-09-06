function Set-Secret {
<#
.DESCRIPTION
curl equivalent
curl --header "X-Vault-Token: hvs.pztinN6NcpcVAi7sGD8qZPP3" --request POST --data '{\"data\":{\"mytest2\":\"myvalue2\"}}' http://127.0.0.1:8200/v1/secret/data/creds
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [object]$Secret,

        [Parameter(Mandatory=$false)]
        [hashtable]$Metadata,

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
    Write-Information "Setting secret $Name in vault $VaultName"

    #set Additional Parameters to shorter variable to stay within 80 column
    $AP = $AdditionalParameters

    #validate additional parameters
    Test-VaultParameters $AP

    #convert Secret to HashTable
    $Data = Switch ($Secret.GetType().Name) {
        'Hashtable' {
            $Secret
        }
        'PSCredential' {
            @{$Secret.Username = $Secret.GetNetworkCredential().Password}
        }
        default {
            Throw "Secret type not supported"
        }
    }

    #convert to json payload
    $JsonBody = @{'data' = $Data} | ConvertTo-Json

    #Construct uri
    $Uri = $AP.Server + $AP.ApiVersion + $AP.Kv2Mount + '/data' + $Name

    Try {
        #try to get data using cached token
        $Token = Get-CachedToken $AP
        $Params = @{
            Uri     = $Uri
            Method  = 'Post'
            Headers = @{'X-Vault-Token' = $Token}
            Body    = $JsonBody
        }
        Invoke-RestMethod @Params | Out-Null
    }
    Catch {
        #if it fails, try with a fresh token
        $Token = Get-Token $AP
        $Params = @{
            Uri     = $Uri
            Method  = 'Post'
            Headers = @{'X-Vault-Token' = $Token}
            Body    = $JsonBody
        }
        Invoke-RestMethod @Params | Out-Null

        #set the token that succeeded to cache for next use
        Set-CachedToken $AP.TokenCachePath $Token
    }
}
