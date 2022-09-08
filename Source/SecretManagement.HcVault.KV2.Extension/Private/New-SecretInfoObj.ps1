function New-SecretInfoObj([string]$VaultName,[string]$Uri,[string]$Token,[int]$Depth) {
<#
.SYNOPSIS
recursively go through the hashicorp vault kv2 key paths,
and return as a secret info object

.DESCRIPTION
the following curl command to a path containing the 'metadata' word shows what keys
are available at the given path:

curl -s -X LIST --header "X-Vault-Token: xxx" http://127.0.0.1:8200/v1/secret/metadata |
jq -r '.data.keys'
[
  "creds", #paths that do not end in slash mean it is a key that holds fields and values
  "creds/" #paths that end in a slash mean they are a 'folder' that we need to recurse through
]

for the above example, 'creds/' is appended to the url and passed back into the function,
and 'creds' is output as a secret info object:

Name      - /creds
Type      - [Microsoft.PowerShell.SecretManagement.SecretType]::Hashtable
VaultName - name of the vault as it was registered with Register-Vault
MetaData  - metadata from the parent path '/creds' as ReadOnlyDictionary<string,object>

the value from the Name property could then be used with the Get-Secret cmdlet
to further drill down and get specific subkeys etc. Example:

Get-SecretInfo -VaultName pestertestvault
Name             Type      VaultName
----             ----      ---------
/creds           Hashtable pestertestvault

Get-Secret -Name '/creds/*' -VaultName nameofvault
#>

    $Keys = (
        Invoke-RestMethod -Uri $Uri -Headers @{"X-Vault-Token"="$Token"} -Body @{list='true'}
    ).data.keys

    ForEach ($Key in $Keys) {
        if ($Key[-1] -eq '/') {
            $Uri   += "/$Key".TrimEnd('/')
            $Depth += 1
            New-SecretInfoObj -VaultName $VaultName -Uri $Uri -Token $Token -Depth $Depth
        }
        else {
            $KeyUri = $Uri.TrimEnd('/') + "/$Key"

            $MetaData = (
                Invoke-RestMethod -Uri $KeyUri -Headers @{"X-Vault-Token"="$Token"}
            ).data

            $MetaDataReadOnlyDict = $MetaData | ConvertTo-ReadOnlyDict

            $SecretName = $KeyUri.Split('/')[-($Depth+1)..-1] |
                Join-String -Separator '/' -OutputPrefix '/'

            $SecretType = [Microsoft.PowerShell.SecretManagement.SecretType]::Hashtable

            [Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
                $SecretName,
                $SecretType,
                $VaultName,
                $MetaDataReadOnlyDict
            )
        }
    }
}
