Function Get-ChildrenFromYammer{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$uri,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$include_thumbnail,

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
        }

        #lauch query
        $children_objects = Get-YammerGraphObject @args
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
                    include_thumbnail =$include_thumbnail;
                    size = $size;
                }

                $all_files += Get-FileInfoFromYammer @args
            }
        }
        if($Folders){
            #Get items from folders
            foreach($folder in $Folders){
                Write-Verbose ("Trying  to get items from {0} folder" -f $folder.webUrl)
                $args = @{
                    folder = $folder;
                    Authentication = $authentication;
                    include_thumbnail =$include_thumbnail;
                    size = $size;
                }
                $all_files+= Get-FolderFromYammer @args
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
                }
                $all_files += Get-FileInfoFromYammer @args
            }
        }
    }
    End{
        return $all_files
    }
}
