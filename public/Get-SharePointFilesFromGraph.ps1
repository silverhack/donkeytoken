Function Get-SharePointFilesFromGraph{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$authentication
    )
    try{
        #Get all sites
        $uri = "sites?search="
        $params = @{
            Authentication = $authentication;
            Method = "GET";
            ObjectType = $uri;
            APIVersion = "V1.0";
            Verbose = $PSBoundParameters['Verbose'];
            Debug = $PSBoundParameters['Debug'];
        }
        $sites = Get-GraphObject @params
        $all_files = @()
        #Check if files and folders
        if($sites){
            Write-Information ("Found {0} sites" -f $sites.Count)
            foreach($site in $sites){
                Write-Information ("Trying to get files from {0} site" -f $site.displayName)
                $uri_path = ("sites/{0}/drive/root" -f $site.id)
                $args = @{
                    Authentication = $authentication;
                    Method = "GET";
                    uri = $uri_path;
                    site_id = $site.id;
                    Verbose = $PSBoundParameters['Verbose'];
                    Debug = $PSBoundParameters['Debug'];
                }
                $data = Get-ChildrenFromGraph @args
                if($data){
                    foreach($elem in $data){$elem | Add-Member -MemberType NoteProperty -Name "SiteId" -Value $site.id}
                    $all_files+=$data
                }
            } 
        }
        if($all_files){
            return $all_files
        }
        else{
            Write-Warning ("No Files were found in Sharepoint")            
        } 
    }
    catch{
        Write-Warning ("Unable to get sharepoint data from Graph")
        Write-Verbose $_
        return $null
    }
}