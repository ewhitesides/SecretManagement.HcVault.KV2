#!/usr/bin/pwsh

$Modules=@('Pester','Microsoft.PowerShell.SecretManagement')

ForEach ($Module in $Modules) {
    Install-Module $Module -Force
}
