Function Get-RootDriveFromYammer{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$authentication
    )
    try{
        #Get user's Drive
        $p = @{
            Authentication = $authentication
            ObjectType =  "drive/root"
        }
        $drive = Get-YammerGraphObject @p
        if($drive){
            return $drive
        }
        else{
            return $false
        }
    }
    catch{
        Write-Verbose $_
        return $false
    }
}