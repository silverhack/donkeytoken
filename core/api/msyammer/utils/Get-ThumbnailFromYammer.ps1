Function Get-ThumbnailFromYammer{
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
        $p = @{
            Authentication = $authentication;
            ObjectType = $thumb_uri;
        }
        $thumb_item = Get-YammerGraphObject @p
        #return thumbnail
        return $thumb_item
    }
    catch{
        Write-Verbose ("Unable to get thumbnail")
        Write-Verbose $_ 
        return $null
    }
}