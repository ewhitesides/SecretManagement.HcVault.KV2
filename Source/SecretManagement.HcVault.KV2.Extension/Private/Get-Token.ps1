function Get-Token([hashtable]$AP) {

    #If AuthType is Ldap, use contents at LdapCredPath to get a token
    if ($AP.AuthType -eq 'LDAP') {

        $VaultAuthLdapPath = $AP.Server + $AP.ApiVersion + '/auth/ldap/login'

        $LdapCredential = Import-CliXml -Path $AP.LdapCredPath
        $UserName       = $LdapCredential.GetNetworkCredential().Username
        $PlainPassword  = $LdapCredential.GetNetworkCredential().Password

        $Params = @{
            Method = 'Post'
            Uri    = "$VaultAuthLdapPath/$UserName"
            Body   = @{password = $PlainPassword} | ConvertTo-Json
        }
        $Output = (Invoke-RestMethod @Params).auth.client_token
    }

    $Output
}
