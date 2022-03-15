Function Get-WebResponseDetailedMessage{
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$response
    )      
    if($response -is [System.Net.HttpWebResponse]){
        try{
            #Write response headers
            Write-Debug -Message ("Response-Headers: {0}" -f $response.Headers)
            #Write Status Code
            Write-Debug -Message ("Status-Code: {0}" -f $response.StatusCode)
            #Write Server Header
            Write-Debug -Message ("Response-Uri: {0}" -f $response.ResponseUri)
            #Close http web response
            [void]$response.Close()
            [void]$response.Dispose()
        }
        catch{
            Write-Debug -Message "Unable to get HttpWebResponse"
        }
    }
    else{
        Write-Debug -Message ("Unknown HttpWebResponse object: {0}" -f $response)
    }
}