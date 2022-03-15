Function Get-RootDriveFromGraph{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$authentication
    )
    try{
        #Get user's Drive
        $args = @{
            Authentication = $authentication;
            Method = "GET";
            ObjectType = "drive/root";
            APIVersion = "beta";
            Verbose = $PSBoundParameters['Verbose'];
            Debug = $PSBoundParameters['Debug'];
        }
        $drive = Get-GraphObject @args
        if($drive){
            return $drive
        }
        else{
            return $false
        }
    }
    catch{
        return $false
    }
}