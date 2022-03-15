Function Get-FolderFromYammer{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$folder,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$drive,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$include_thumbnail,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("small","medium","large")]
        [String]$size = "large"
    )
    if($folder.folder.childCount -gt 0){
        $children_uri = ("drives/{0}/items/{1}" -f $folder.parentReference.driveId, $folder.id)
        $args = @{
            uri = $children_uri;
            Authentication = $authentication;
            include_thumbnail =$include_thumbnail;
            size = $size;
        }
        $folder_items = Get-ChildrenFromYammer @args
        if($folder_items){
            return $folder_items
        }
    }
}