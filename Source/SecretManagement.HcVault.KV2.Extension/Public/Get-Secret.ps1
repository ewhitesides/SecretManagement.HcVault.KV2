function Get-Secret {
    [CmdletBinding()]
    Param(
        #The name of the secret as passed through from Get-Secret -Name
        #This should be the equivalent of field arg (vault kv get -field=)
        [Parameter(Mandatory)]
        [string]$Name,

        #The name of the vault as passed through SecretManagement module
        [Parameter(Mandatory)]
        [Alias('Vault')]
        [string]$VaultName,

        #Parameters for vault as passed through Register-SecretVault -VaultParameters
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
    $Uri = $AP.Server + $AP.ApiVersion + $AP.Kv2Mount + '/data' + $AP.Kv2Path

    Try {
        #try to get secret using cached token
        $Token = Get-CachedToken $AP.TokenCachePath
        $IrmGetSecretParams = @{
            Uri = $Uri
            Headers = @{"X-Vault-Token"="$Token"}
        }
        (Invoke-RestMethod @IrmGetSecretParams).data.data |
        Select-Object -ExpandProperty $Name
    }
    Catch {
        #if it fails, try with a fresh token
        $Token = Get-Token $AP
        $IrmGetSecretParams = @{
            Uri = $Uri
            Headers = @{"X-Vault-Token"="$Token"}
        }
        (Invoke-RestMethod @IrmGetSecretParams).data.data |
        Select-Object -ExpandProperty $Name
    }
    Finally {
        #set the token that succeeded to cache for next use
        Set-CachedToken $AP.TokenCachePath $Token
    }
}
