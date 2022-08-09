#!/bin/bash

modules=('Pester' 'Microsoft.PowerShell.SecretManagement')

for module in "${modules[@]}"; do
    /usr/bin/pwsh -Command "Install-Module $module -Force"
done
