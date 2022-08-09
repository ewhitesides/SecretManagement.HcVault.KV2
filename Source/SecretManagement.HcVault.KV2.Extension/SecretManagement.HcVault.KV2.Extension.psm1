#used structure from https://github.com/powershell/secretmanagement README

#import private functions
$GetPrivateItems = @{
    Path    = "$PSScriptRoot/Private/*.ps1"
    Exclude = '*.Tests.ps1'
}
Get-Item @GetPrivateItems | ForEach-Object {
    . $_
}

#import public functions and export
$GetPublicItems = @{
    Path    = "$PSScriptRoot/Public/*.ps1"
    Exclude = '*.Tests.ps1'
}
$PublicFunctions = Get-Item @GetPublicItems | ForEach-Object {
    . $_
    $_.BaseName
}
Export-ModuleMember -Function $PublicFunctions