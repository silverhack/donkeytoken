Function Get-FileInfoFromYammer{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$file,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$include_thumbnail,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$size = "large"
    )
    try{
        
        $fileinfo = New-Object psobject
        $fileinfo | Add-Member -MemberType NoteProperty -Name "Name" -Value $file.name
        $fileinfo | Add-Member -MemberType NoteProperty -Name "ItemType" -Value (&{If($file.package.Type -eq "OneNote") {"Notebook"} Else {"File"}})
        $fileinfo | Add-Member -MemberType NoteProperty -Name "Shared" -Value (&{If($file.shared) {"Yes"} Else {"No"}})
        $fileinfo | Add-Member -MemberType NoteProperty -Name "downloadUrl" -Value $file.'@microsoft.graph.downloadUrl'
        $fileinfo | Add-Member -MemberType NoteProperty -Name "fileInfo" -Value $file.fileSystemInfo
        $fileinfo | Add-Member -MemberType NoteProperty -Name "parentReference" -Value $file.parentReference
        if($include_thumbnail){
            $p = @{
                authentication = $authentication;
                item = $file;
                size = $size;
                thumbId = 0;                
            }
            $thumbnail = Get-ThumbnailFromYammer @p
            #Add to object
            $fileinfo | Add-Member -MemberType NoteProperty -Name "thumbnail" -Value $thumbnail
        }
        #return object
        return $fileinfo
    }
    catch{
        return $false
    }
}