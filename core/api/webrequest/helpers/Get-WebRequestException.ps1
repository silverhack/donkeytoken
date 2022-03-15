Function Get-WebRequestException{
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [System.Management.Automation.ErrorRecord]$Exception,

        [parameter(Mandatory=$False, HelpMessage='URL error')]
        [String]$Url
    )
    try{
        if($Url){
            Write-Verbose -Message ("Unable to process URL: {0}" -f $Url)
        }
        try{
            $StatusCode = ($Exception.Exception.Response.StatusCode.value__ ).ToString().Trim();            
        }
        catch{
            $StatusCode = "-1"
        }
        try{
            $errorMessage = ($Exception.Exception.Message).ToString().Trim();
        }
        catch{
            $errorMessage = "Unknown error message"
        }
        #Write error message
        Write-Verbose -Message ("[{0}]: {1}" -f $StatusCode, $errorMessage)
        try{
            $responseBody = $null;
            #Get Exception Body Message
            $reader = [System.IO.StreamReader]::new($Exception.Exception.Response.GetResponseStream())
            if($null -ne $reader){
                #$reader.BaseStream.Position = 0
                #$reader.DiscardBufferedData()
                #$responseBody = $reader.ReadToEnd()
                #while (-not $reader.AsyncWaitHandle.WaitOne(200)) { }
                $responseBody = $reader.ReadToEndAsync().GetAwaiter().GetResult();
            }
            #Check if valid JSON and writes error message
            if($null -ne $responseBody){
                try{
                    $detailed_message = ConvertFrom-Json $responseBody
                    if($detailed_message.psobject.properties.name -match 'odata.error'){
                        $errorCode = $detailed_message.'odata.error'.code
                        $errorMessage = $detailed_message.'odata.error'.message.value
                        if($null -ne $errorCode){
                            Write-Verbose -Message $errorCode   
                        }
                        if($null -ne $errorMessage){
                            Write-Verbose -Message $errorMessage
                        }
                    }
                    elseif($detailed_message.psobject.properties.name -match 'error_description'){
                        try{
                            $error = $detailed_message.error
                        }
                        catch{
                            $error = $null
                        }
                        try{
                            $errorMessage = $detailed_message.error_description
                        }
                        catch{
                            $errorMessage = $null
                        }
                        if($null -ne $error){
                            Write-Verbose -Message $error   
                        }
                        if($null -ne $errorMessage){
                            Write-Verbose -Message $errorMessage
                        }                        
                    }
                    elseif($detailed_message.psobject.properties.name -match 'error'){
                        try{
                            $errorCode = $detailed_message.error.code
                        }
                        catch{
                            $errorCode = $null
                        }
                        try{
                            $errorMessage = $detailed_message.error.message
                        }
                        catch{
                            $errorMessage = $null
                        }
                        if($null -ne $errorCode){
                            Write-Verbose -Message $errorCode   
                        }
                        if($null -ne $errorMessage){
                            Write-Verbose -Message $errorMessage
                        }
                    }
                    elseif($detailed_message.psobject.properties.name -match 'message'){
                        try{
                            $errorCode = $detailed_message.code
                        }
                        catch{
                            $errorCode = $null
                        }
                        try{
                            $errorMessage = $detailed_message.message
                        }
                        catch{
                            $errorMessage = $null
                        }
                        if($null -ne $errorCode){
                            Write-Verbose -Message $errorCode   
                        }
                        if($null -ne $errorMessage){
                            Write-Verbose -Message $errorMessage
                        }
                    }
                }
                catch{
                    #Write detailed error message
                    Write-Verbose -Message ("Detailed error message: {0}" -f $responseBody)
                }
            }
            else{
                #Unable to get detailed error message
                Write-Verbose -Message "Unable to get detailed error message"
            }
        }
        catch{
            #Unable to get detailed error message
            Write-Verbose -Message "Unable to get detailed error message"
        }
    }
    catch{
        #Writes detailed error message
        Write-Verbose -Message "Unable to get error message"
        #Write detailed error message
        Write-Verbose -Message $_.Exception
    }
}