Function Get-FileInfoFromGraph{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$file,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$include_thumbnail,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$downloadFile,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$size = "large",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$site_id
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
            $args = @{
                Authentication = $authentication;
                item = $file;
                size = $size;
                thumbId = 0;
                Verbose = $PSBoundParameters['Verbose'];
                Debug = $PSBoundParameters['Debug'];
            }
            $thumbnail = Get-ThumbnailFromGraph @args
            #Add to object
            $fileinfo | Add-Member -MemberType NoteProperty -Name "thumbnail" -Value $thumbnail
        }
        if($downloadFile){
            $raw_data = Get-RawDataFromGraph -authentication $authentication -item $file -site_id $site_id
            #Add to object
            $fileinfo | Add-Member -MemberType NoteProperty -Name "raw_data" -Value $raw_data
        }
        #return object
        return $fileinfo
    }
    catch{
        return $false
    }
}