Function Get-RedirectFromKmsi{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false, HelpMessage="config file")]
        [object]$config
    )
    Begin{
        $auth_flow = $body = $response = $valid_response = $null
        $mskmsiurl = "https://login.microsoftonline.com/kmsi"
        #Set headers
        $headers=@{
                "Upgrade-Insecure-Requests" = "1"
        }
        #construct body
        if($config.PSObject.Properties.Item('sFT') -and $config.PSObject.Properties.Item('canary') -and $config.PSObject.Properties.Item('sCtx')){
            $body=@{
                "LoginOptions"="0"
                "flowToken"=$config.sFT
                "canary"=$config.canary
                "ctx"=$config.sCtx
                "hpgrequestid"=(New-Guid).ToString()
            }
            #convert body
            $body = ($body.GetEnumerator() | % { "$($_.Key)=$($_.Value)" }) -join '&'
        }
        elseif($config.PSObject.Properties.Item('unsafe_strTopMessage')){
            Write-Warning $config.unsafe_strTopMessage
        }
    }
    Process{
        if($body){
            try{
                $param = @{
                    Url = $mskmsiurl;
                    Method = "Post";
                    Data = $body;
                    Content_Type = "application/x-www-form-urlencoded";
                    Headers= $headers;
                    Cookies = $cookiejar.GetCookieHeader("https://login.microsoftonline.com")
                    CookieContainer = $cookiejar;
                    returnRawResponse = $True;
                    Referer = "https://login.microsoftonline.com/common/login";
                    Verbose = $PSBoundParameters['Verbose'];
                    Debug = $PSBoundParameters['Debug'];
                }
                $response = New-WebRequest @param
            }
            catch{
                Write-Warning ($Script:messages.UnableToGetAuthenticationFlow -f $mskmsiurl)
            }
            if($response){
                $location = $response.Headers['Location']
                if($location){
                    [void]$response.Close()
                    [void]$response.Dispose()
                    $param = @{
                        Url = $location;
                        Method = "Get";
                        AllowAutoRedirect= $True;
                        CookieContainer= $cookiejar;
                        returnRawResponse= $true;
                        Referer = "https://login.microsoftonline.com/";
                        Content_Type = "application/x-www-form-urlencoded";
                        Verbose = $PSBoundParameters['Verbose'];
                        Debug = $PSBoundParameters['Debug'];
                    }
                    $valid_response = New-WebRequest @param
                }
                else{
                    #Try to get config
                    $raw_response = Get-ResponseStream -WebResponse $response
                    [void]$response.Close()
                    [void]$response.Dispose()
                    $config = Get-ConfigFromUrl $raw_response
                    if($null -ne $config -and $config.urlPost -like '*consent*'){
                        $body=@{
                            "acceptConsent" = "true"
                            "flowToken"=$config.sFT
                            "canary"= [System.Web.HttpUtility]::UrlEncode($config.canary);
                            "ctx"=$config.sCtx
                            "hpgrequestid"=(New-Guid).ToString()
                        }
                        #convert body
                        $body = ($body.GetEnumerator() | % { "$($_.Key)=$($_.Value)" }) -join '&'
                        $consent_url = "https://login.microsoftonline.com/common/Consent/Set"
                        try{
                            $param = @{
                                Url = $consent_url;
                                Method = "Post";
                                Data = $body;
                                Content_Type = "application/x-www-form-urlencoded";
                                Headers= $headers;
                                Cookies = $cookiejar.GetCookieHeader("https://login.microsoftonline.com/common/login")
                                CookieContainer = $cookiejar;
                                returnRawResponse = $True;
                                Referer = "https://login.microsoftonline.com/common/login";
                                Verbose = $PSBoundParameters['Verbose'];
                                Debug = $PSBoundParameters['Debug'];
                            }
                            $raw_response = New-WebRequest @param
                            $valid_response = $raw_response.Headers['Location']
                            [void]$raw_response.Close()
                            [void]$raw_response.Dispose()
                        }
                        catch{
                            Write-Warning ($Script:messages.UnableToGetAuthenticationFlow -f $consent_url)
                        }
                    }
                }
            }
        }
    }
    End{
        if($valid_response){
            return $valid_response            
        }
        else{
            Write-Warning ($Script:messages.UnableToGetRedirectUrl -f $mskmsiurl)
            if($config.PSObject.Properties.Item('pgid')){
                Write-Warning ("The error was: {0}" -f $config.pgid)
            }
            if($config.PSObject.Properties.Item('strServiceExceptionMessage')){
                Write-Warning $config.strServiceExceptionMessage
            }
        }
    }
}