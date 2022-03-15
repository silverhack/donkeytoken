Function Get-ResponseStream{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false, HelpMessage="config file")]
        [Object]$WebResponse
    )
    try{
        #Get the response stream
        $rs = $WebResponse.GetResponseStream();
        #Get Stream Reader and store into a RAW var
        [System.IO.StreamReader] $sr = New-Object System.IO.StreamReader -argumentList $rs     
        [string]$raw_response = $sr.ReadToEnd()
        #Close Stream reader
        $sr.Close()
        $sr.Dispose()
        $WebResponse.Close();
        $WebResponse.Dispose();
        return $raw_response
    }
    catch{
        Write-Warning "Unable to get response"
        return $null
    }
}