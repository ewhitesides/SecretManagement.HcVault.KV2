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

    #Validate AdditionalParameters
    Test-VaultParameters $AdditionalParameters

    #Create vault url path vars
    $VaultRoot = $AdditionalParameters.Server + '/v1'

    #If AuthType is Ldap, use contents at LdapCredPath to get a token
    if ($AdditionalParameters.AuthType -eq 'LDAP') {
        $VaultAuthLdapLogin = $VaultRoot+'/auth/ldap/login'
        $LdapCredential     = Import-CliXml -Path $AdditionalParameters.LdapCredPath
        $UserName           = $LdapCredential.GetNetworkCredential().Username
        $PlainPassword      = $LdapCredential.GetNetworkCredential().Password
        $IrmGetTokenParams  = @{
            Method = 'Post'
            Uri    = "$VaultAuthLdapLogin/$UserName"
            Body   = @{password = $PlainPassword} | ConvertTo-Json
        }
        [ValidateNotNullOrEmpty()]
        $Token = (Invoke-RestMethod @IrmGetTokenParams).auth.client_token
    }

    $IrmGetSecretParams = @{
        Uri = $VaultRoot +
            "/$($AdditionalParameters.Kv2Mount)/data" +
            "/$($AdditionalParameters.Kv2Path)"
        Headers = @{"X-Vault-Token"="$Token"}
    }
    (Invoke-RestMethod @IrmGetSecretParams).data.data | Select-Object -ExpandProperty $Name
}