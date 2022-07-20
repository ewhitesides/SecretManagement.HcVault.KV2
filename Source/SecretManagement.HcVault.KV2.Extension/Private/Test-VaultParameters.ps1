function Test-VaultParameters ([hashtable]$VaultParameters) {
<#
.DESCRIPTION
internal function to make sure vault parameters are what we expect
#>
    $RequiredKeys = @(
        'Server'
        'AuthType'
        'Kv2Mount'
        'Kv2Path'
    )

    if ($VaultParameters.AuthType -eq 'LDAP') {
        $RequiredKeys += @(
            'LdapCredPath'
        )
    }

    #Verify user provided all the required keys
    ForEach ($Key in $RequiredKeys) {
        if ($Key -notin $VaultParameters.Keys) {
            Throw "VaultParameters: Key '$Key' is required"
        }
    }
}