using namespace System.Collections.ObjectModel
using namespace System.Collections.Generic
function ConvertTo-ReadOnlyDictionary {
<#
.DESCRIPTION
Converts a hashtable to a ReadOnlyDictionary[String,Object].
Needed for SecretInformation metadata property.
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)][hashtable]$hashtable
    )
    process {
        $dictionary = [SortedDictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
        $hashtable.GetEnumerator().foreach{
            $dictionary[$_.Name] = $_.Value
        }
        [ReadOnlyDictionary[string,object]]::new($dictionary)
    }
}