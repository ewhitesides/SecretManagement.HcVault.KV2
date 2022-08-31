function New-SecretInfoObj([string]$VaultName,[string]$Uri,[string]$Token,[int]$Depth) {

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

            $MetaDataResponse = (
                Invoke-RestMethod -Uri $SubKeyUri -Headers @{"X-Vault-Token"="$Token"}
            ).data.metadata

            [ReadOnlyDictionary[String,Object]]$MetaData = [ordered]@{
                created_time    = $MetaDataResponse.created_time
                custom_metadata = $MetaDataResponse.custom_metadata
                deletion_time   = $MetaDataResponse.deletion_time
                destroyed       = $MetaDataResponse.destroyed
                version         = $MetaDataResponse.version
            } | ConvertTo-ReadOnlyDictionary

            $SubKeys = (
                Invoke-RestMethod -Uri $SubKeyUri -Headers @{"X-Vault-Token"="$Token"}
            ).data.subkeys.PSObject.Properties.Name

            if ($SubKeys) {
                ForEach ($SubKey in $SubKeys) {
                    [String]$SecretName     = "$SubKeyUri/$SubKey".Split('/')[-($Depth+2)..-1] -join '/'
                    [Microsoft.PowerShell.SecretManagement.SecretType]$SecretType = 'String'
                    [Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
                        $SecretName, $SecretType, $VaultName, $MetaData
                    )
                }
            }
            else {
                [String]$SecretName     = $SubKeyUri.Split('/')[-($Depth+2)..-1] -join '/'
                [Microsoft.PowerShell.SecretManagement.SecretType]$SecretType = 'String'
                [Microsoft.PowerShell.SecretManagement.SecretInformation]::new(
                    $SecretName, $SecretType, $VaultName, $MetaData
                )
            }
        }
    }
}