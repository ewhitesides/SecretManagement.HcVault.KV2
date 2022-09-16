function ConvertTo-HashTable {
    Param(
        [Parameter(ValueFromPipeline)]
        [PSCustomObject]$Incoming
    )

    Process {
        #create hashtable
        $Output = @{}

        #store the properties of the object into hashtable
        $Incoming.psobject.properties | ForEach-Object {
            $Output[$_.Name] = $_.Value
        }

        #return
        $Output
    }
}