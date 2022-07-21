function Get-Token([hashtable]$AdditionalParameters) {

    #If AuthType is Ldap, use contents at LdapCredPath to get a token
    if ($AdditionalParameters.AuthType -eq 'LDAP') {

        $VaultAuthLdapPath = $AdditionalParameters.Server +
            $AdditionalParameters.ApiVersion +
            '/auth/ldap/login'

        $LdapCredential = Import-CliXml -Path $AdditionalParameters.LdapCredPath
        $UserName       = $LdapCredential.GetNetworkCredential().Username
        $PlainPassword  = $LdapCredential.GetNetworkCredential().Password

        $IrmGetTokenParams = @{
            Method = 'Post'
            Uri    = "$VaultAuthLdapPath/$UserName"
            Body   = @{password = $PlainPassword} | ConvertTo-Json
        }
        $Output = (Invoke-RestMethod @IrmGetTokenParams).auth.client_token
    }

    $Output
}
