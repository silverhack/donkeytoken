Function Get-DriveDataFromYammer{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$authentication
    )
    try{
        #Set verbosity
        if($PSBoundParameters.Verbose){
            $VerboseOptions=@{Verbose=$true}
        }
        else{
            $VerboseOptions=@{Verbose=$false}
        }
        #Check Debug options
        if($PSBoundParameters.Debug){
            $VerboseOptions.Add("Debug",$true)
            $DebugPreference = 'Continue'
        }
        else{
            $VerboseOptions.Add("Debug",$false)
        }
        #Set script var
        Set-Variable VerboseOptions -Value $VerboseOptions -Scope Script -Force        
        #Get user's Drive
        $p = @{
            authentication= $authentication  
        }
        $drive = Get-RootDriveFromYammer @p
        #Check if files and folders
        if($drive -and $drive.folder.childCount -ne 0){
            #Get children
            $uri_path = "drive/root"
            $p = @{
                authentication = $authentication
                uri = "drive/root"
                include_thumbnail = $True
                size = "large"
            }
            $data = Get-ChildrenFromYammer @p
            return $data
        }   
    }
    catch{
        Write-Warning ("Unable to get drive data from Graph") -ForegroundColor Yellow
        Write-Warning $_.Exception.Message
        Write-Verbose $_ 
        return $null
    }
}