Function Get-DriveDataFromGraph{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$authentication
    )
    try{
        #Get user's Drive
        $drive = Get-RootDriveFromGraph -authentication $authentication 
        #Check if files and folders
        if($drive -and $drive.folder.childCount -ne 0){
            #Get children
            $args = @{
                Authentication = $authentication;
                Method = "GET";
                uri = "drive/root";
                api_version = "v1.0";
                include_thumbnail = $True;
                size = "large";
                downloadFile= $True;
                Verbose = $PSBoundParameters['Verbose'];
                Debug = $PSBoundParameters['Debug'];
            }
            $data = Get-ChildrenFromGraph @args
            return $data
        }   
    }
    catch{
        Write-Warning ("Unable to get drive data from Graph")
        Write-Verbose $_ 
        return $null
    }
}