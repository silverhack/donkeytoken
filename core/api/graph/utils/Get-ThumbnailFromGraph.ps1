Function Get-ThumbnailFromGraph{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$item,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$size = "large",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$thumbId = 0
    )
    try{
        #start microsoft-edge:$($thumb_item.url)
        Write-Verbose ("Trying to get thumbnail image for {0}" -f $item.name)
        $thumb_uri = ("drives/{0}/items/{1}/thumbnails/{2}/{3}" -f $item.parentReference.driveId, $item.id, $thumbId, $size)
        $args = @{
            Authentication = $authentication;
            Method = "GET";
            ObjectType = $thumb_uri;
            APIVersion = "v1.0";
            Verbose = $PSBoundParameters['Verbose'];
            Debug = $PSBoundParameters['Debug'];
        }
        $thumb_item = Get-GraphObject @args
        #return thumbnail
        return $thumb_item
    }
    catch{
        Write-Warning ("Unable to get thumbnail")
        Write-Verbose $_ 
        return $null
    }
}