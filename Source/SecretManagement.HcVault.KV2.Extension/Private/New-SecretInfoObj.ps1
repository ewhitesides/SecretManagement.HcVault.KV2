function New-SecretInfoObj([string]$VaultName,[string]$Uri,[string]$Token,[int]$Depth) {


#TODO organize all of this
#get subkeys at this path
#curl --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/subkeys/creds

#get further paths at this path
#curl --request LIST --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/metadata/creds

# PS /workspaces/SecretManagement.HcVault.KV2/Test/Unit> curl --request LIST --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/metadata
# {"request_id":"c5ad60bf-98a4-6850-c0f7-386af81b0c6a","lease_id":"","renewable":false,"lease_duration":0,"data":{"keys":["creds","creds/"]},"wrap_info":null,"warnings":null,"auth":null}
# PS /workspaces/SecretManagement.HcVault.KV2/Test/Unit>
# PS /workspaces/SecretManagement.HcVault.KV2/Test/Unit> curl --request LIST --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/subkeys/creds
# {"errors":["1 error occurred:\n\t* unsupported operation\n\n"]}
# PS /workspaces/SecretManagement.HcVault.KV2/Test/Unit> curl --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/subkeys/creds
# {"request_id":"d6bc1136-f8f7-0199-3462-f2e3c2a70423","lease_id":"","renewable":false,"lease_duration":0,"data":{"metadata":{"created_time":"2022-08-31T02:51:59.365219274Z","custom_metadata":null,"deletion_time":"","destroyed":false,"version":2},"subkeys":{"mypass":null}},"wrap_info":null,"warnings":null,"auth":null}
# PS /workspaces/SecretManagement.HcVault.KV2/Test/Unit> curl --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/subkeys/creds/creds
# {"errors":[]}
# PS /workspaces/SecretManagement.HcVault.KV2/Test/Unit> curl --request LIST --header "X-Vault-Token: hvs.WBgxmQrsijvirYj7BfOBcnTS" http://127.0.0.1:8200/v1/secret/metadata/creds/
# {"request_id":"2baac4b3-a915-0e37-c37d-bcf2c4b9c055","lease_id":"","renewable":false,"lease_duration":0,"data":{"keys":["something"]},"wrap_info":null,"warnings":null,"auth":null}

#TODO: Find out why the fully qualified is required on Linux even though using Namespace is defined above

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