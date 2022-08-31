using namespace Microsoft.PowerShell.SecretManagement

[SecretInformation]::new(
    'test',      # Name of secret
    'String',      # Secret data type [Microsoft.PowerShell.SecretManagement.SecretType]
    'somevault',       # The name of our vault, provided as a parameter by Secret Management
    $null         # The metadata of our vault as expressed as a hashtable.
)

