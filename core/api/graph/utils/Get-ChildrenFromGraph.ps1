Function Get-ChildrenFromGraph{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$uri,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$site_id,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$api_version = "v1.0",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("CONNECT","GET","POST","HEAD","PUT")]
        [String]$Method = "GET",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$me,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$include_thumbnail,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$downloadFile,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("small","medium","large")]
        [String]$size = "large"
    )
    Begin{
        $all_files = @()
        $children_uri = ("{0}/children" -f $uri)
        #construct args
        $args = @{
            Authentication = $authentication;
            ObjectType = $children_uri;
            APIVersion =$api_version;
            Method = $Method;
            me = $me;
            Verbose = $PSBoundParameters['Verbose'];
            Debug = $PSBoundParameters['Debug'];
        }
        #lauch query
        $children_objects = Get-GraphObject @args
        #Get folders, files and OneNote files
        $Folders = $children_objects | ? {$_.Folder}
        $Files = $children_objects | ? {$_.File}
        $Notebooks = $children_objects | ? {$_.package.type -eq "OneNote"}
    }
    Process{
        if($Files){
            #Get all files
            foreach($file in $Files){
                Write-Verbose ("Processing {0} file" -f $file.Name)
                $args = @{
                    file = $file;
                    Authentication = $authentication;
                    include_thumbnail =$include_thumbnail.IsPresent;
                    size = $size;
                    site_id = $site_id;
                    downloadFile = $downloadFile.IsPresent;
                    Verbose = $PSBoundParameters['Verbose'];
                    Debug = $PSBoundParameters['Debug'];
                }
                $all_files += Get-FileInfoFromGraph @args
            }
        }
        if($Folders){
            #Get items from folders
            foreach($folder in $Folders){
                Write-Verbose ("Trying  to get items from {0} folder" -f $folder.webUrl)
                $args = @{
                    folder = $folder;
                    Authentication = $authentication;
                    api_version = $api_version;
                    include_thumbnail =$include_thumbnail;
                    site_id = $site_id;
                    size = $size;
                    Verbose = $PSBoundParameters['Verbose'];
                    Debug = $PSBoundParameters['Debug'];
                }
                $all_files+= Get-FolderFromGraph @args
            }
        }
        if($Notebooks){
            #Process OneNote files
            foreach ($onenote in $Notebooks) {
                $args = @{
                    file = $onenote;
                    Authentication = $authentication;
                    include_thumbnail =$include_thumbnail;
                    size = $size;
                    site_id = $site_id;
                    downloadFile = $downloadFile;
                    Verbose = $PSBoundParameters['Verbose'];
                    Debug = $PSBoundParameters['Debug'];
                }
                $all_files += Get-FileInfoFromGraph @args
            }
        }
    }
    End{
        return $all_files
    }
}