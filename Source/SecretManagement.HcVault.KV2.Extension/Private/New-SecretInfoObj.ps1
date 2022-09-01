function New-SecretInfoObj([string]$VaultName,[string]$Uri,[string]$Token,[int]$Depth) {
<#
.SYNOPSIS
recursively go through the hashicorp vault kv2 paths and return secret info objects

.DESCRIPTION
recursively go through the hashicorp vault kv2 paths, return fields with their parent paths,
and convert to secret info objects

the following curl command to a path containing the 'metadata' word shows what
child keys are available at the given path:
curl -s -X LIST --header "X-Vault-Token: xxx" http://127.0.0.1:8200/v1/secret/metadata |
jq -r '.data.keys'
[
  "creds", #paths that do not end in slash mean it is a key that holds fields and values
  "creds/" #paths that end in a slash mean they are a 'folder' that we need to recurse through
]

for the above example 'creds' is a terminating path point that contains fields/values
the following curl command with the word 'subkeys' in place of 'metadata' shows what
fields are available at the given path:
curl --header "X-Vault-Token: xxx" http://127.0.0.1:8200/v1/secret/subkeys/creds |
jq -r '.data.subkeys'
{
  "mypass": null
}

we then take the 'mypass' field, along with it's parent paths,
and return as a secret info object with the following property names and values:

Name      - /creds/mypass
Type      - [Microsoft.PowerShell.SecretManagement.SecretType]::String
VaultName - name of the vault as it was registered with Register-Vault
MetaData  - metadata from the parent path '/creds'

the value from the Name property could then be used with the Get-Secret cmdlet:
Get-Secret -Name /creds/mypass -VaultName nameofvault
#>

    $Keys = (
        Invoke-RestMethod -Uri $Uri -Headers @{"X-Vault-Token"="$Token"} -Body @{list='true'}
    ).data.keys

   ForEach ($Key in $Keys) {
        if ($Key[-1] -eq '/') {
            $Uri   += "/$Key"
            $Depth += 1
            New-SecretInfoObj -VaultName $VaultName -Uri $Uri -Token $Token -Depth $Depth
        }
        else {
            $SubKeyUri = $Uri.Replace('metadata','subkeys',1)
            if ($Depth -eq 0) {
                $SubKeyUri += "/$Key"
            }
            else {
                $SubKeyUri += $Key
            }

            $MetaData = (
                Invoke-RestMethod -Uri $SubKeyUri -Headers @{"X-Vault-Token"="$Token"}
            ).data.metadata | ConvertTo-ReadOnlyDict

            $SubKeys = (
                Invoke-RestMethod -Uri $SubKeyUri -Headers @{"X-Vault-Token"="$Token"}
            ).data.subkeys.PSObject.Properties.Name

            if ($SubKeys) {
                ForEach ($SubKey in $SubKeys) {
                    $SecretName = "$SubKeyUri/$SubKey".Split('/')[-($Depth+2)..-1] |
                        Join-String -Separator '/' -OutputPrefix '/'
                    $SecretType = [Microsoft.PowerShell.SecretManagement.SecretType]::String
                    [Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
                        $SecretName, $SecretType, $VaultName, $MetaData
                    )
                }
            }
            else {
                $SecretName = $SubKeyUri.Split('/')[-($Depth+2)..-1] |
                    Join-String -Separator '/' -OutputPrefix '/'
                $SecretType = [Microsoft.PowerShell.SecretManagement.SecretType]::String
                [Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
                    $SecretName, $SecretType, $VaultName, $MetaData
                )
            }
        }
    }
}
