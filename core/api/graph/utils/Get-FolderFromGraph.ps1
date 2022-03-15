Function Get-FolderFromGraph{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$api_version = "v1.0",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$folder,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$drive,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$site_id,

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
            api_version = $api_version;
            include_thumbnail =$include_thumbnail;
            size = $size;
            site_id = $site_id;
            downloadFile = $True;
            Verbose = $PSBoundParameters['Verbose'];
            Debug = $PSBoundParameters['Debug'];
        }
        $folder_items = Get-ChildrenFromGraph @args
        if($folder_items){
            return $folder_items
        }
    }
}