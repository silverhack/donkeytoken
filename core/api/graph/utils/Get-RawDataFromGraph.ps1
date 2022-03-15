Function Get-RawDataFromGraph{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$site_id,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$item
    )
    try{
        #start microsoft-edge:$($thumb_item.url)
        #Write-Verbose ("Trying to get rawdata for {0}" -f $item.name)
        $_uri = ("drives/{0}/items/{1}/content" -f $item.parentReference.driveId, $item.id)
        #Write-Verbose $_uri
        $args = @{
            Authentication = $authentication;
            Method = "GET";
            ObjectType = $_uri;
            APIVersion = "v1.0";
            Verbose = $PSBoundParameters['Verbose'];
            Debug = $PSBoundParameters['Debug'];
        }
        $raw_data = Get-GraphObject @args
        #return raw
        return $raw_data
    }
    catch{
        Write-Warning ("Unable to get raw data")
        Write-Verbose $_ 
        return $null
    }
    
}