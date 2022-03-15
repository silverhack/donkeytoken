Function Get-AuthenticatedResponse{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false, HelpMessage="Web response")]
        [Object]$WebResponse
    )
    Begin{
        try{
            #Get cookies and set new location
            $hostname = ("https://{0}" -f $WebResponse.ResponseUri.Host)
            $location = $WebResponse.Headers['Location']
            $new_location = ("{0}/{1}" -f $hostname, $location)
            #Get cookies
            #$auth_cookies = $WebResponse.Headers['Set-cookie']
            $auth_cookies = $cookiejar.GetCookieHeader($hostname)
            #Close WebResponse
            $WebResponse.Close()
            $WebResponse.Dispose()
            #Construct query
            $param = @{
                Url = $new_location;
                Method = "Get";
                Cookies= $auth_cookies;
                CookieContainer = $cookiejar;
                AllowAutoRedirect = $true;
                returnRawResponse= $true;
                Referer = "https://login.microsoftonline.com/";
                Content_Type = "application/x-www-form-urlencoded";
                Verbose = $PSBoundParameters['Verbose'];
                Debug = $PSBoundParameters['Debug'];
            }
            $authenticated_response = New-WebRequest @param
        }
        catch{
            Write-Warning "Unable to set new location"
            $authenticated_response= $null;
            Write-Verbose $_
        }
    }
    Process{
        if($null -ne $authenticated_response){
            #Get the response stream
            $rs = $authenticated_response.GetResponseStream();
            #Get Stream Reader and store into a RAW var
            [System.IO.StreamReader] $sr = New-Object System.IO.StreamReader -argumentList $rs     
            [string]$raw_response = $sr.ReadToEnd()
            #Close Stream reader
            $sr.Close()
            $sr.Dispose()
        }
        else{
            $raw_response = $null
        }
    }
    End{
        if($null -ne $raw_response){
            return $raw_response
        }
        else{
            return $null
        }
    }
}