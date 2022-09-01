using namespace System.Collections.ObjectModel
using namespace System.Collections.Generic
function ConvertTo-ReadOnlyDict {
<#
.DESCRIPTION
Converts a PSCustomObject to a ReadOnlyDictionary[String,Object].
Needed for SecretInformation metadata property.
#>
    param(
        [Parameter(ValueFromPipeline)]
        [PSCustomObject]$Incoming
    )

    process {
        $dictionary = [SortedDictionary[string,object]]::new(
            [StringComparer]::OrdinalIgnoreCase
        )

        $Incoming.PSObject.Properties | Sort-Object -Property 'Name' |
        ForEach-Object {
            $dictionary.Add($_.Name, $_.Value)
        }

        [ReadOnlyDictionary[string,object]]::new($dictionary)
    }
}