Function Get-FlowFromKmsi{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false, HelpMessage="config file")]
        [object]$config
    )
    Begin{
        $auth_flow = $body = $null
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
                    Cookies = $cookiejar.GetCookieHeader("https://login.microsoftonline.com");
                    CookieContainer = $cookiejar;
                    Referer = "https://login.microsoftonline.com/common/login";
                    Verbose = $PSBoundParameters['Verbose'];
                    Debug = $PSBoundParameters['Debug'];
                }
                [xml]$raw_ = New-WebRequest @param
                #$auth_cookies = $cookiejar.GetCookies("https://login.microsoftonline.com/kmsi")
                #Set-Variable kmsi_cookies -Value $auth_cookies -Scope Script -Force
                #Get code, id_token... from xml data
                $hidden_form = $raw_.SelectSingleNode("//form[@name='hiddenform']").action
                $code = $raw_.SelectSingleNode("//input[@name='code']").value
                $id_token = $raw_.SelectSingleNode("//input[@name='id_token']").value
                $state = $raw_.SelectSingleNode("//input[@name='state']").value
                $session_state = $raw_.SelectSingleNode("//input[@name='session_state']").value
                #create PsObject
                $auth_flow = New-Object -TypeName PSCustomObject
                $auth_flow | Add-Member -type NoteProperty -name hidden_form -value $hidden_form
                $auth_flow | Add-Member -type NoteProperty -name code -value $code
                $auth_flow | Add-Member -type NoteProperty -name id_token -value $id_token
                $auth_flow | Add-Member -type NoteProperty -name state -value $state
                $auth_flow | Add-Member -type NoteProperty -name session_state -value $session_state
            }
            catch{
                Write-Warning ($Script:messages.UnableToGetAuthenticationFlow -f $mskmsiurl)
            }
        }
    }
    End{
        if($auth_flow){
            return $auth_flow            
        }
        else{
            Write-Warning ($Script:messages.UnableToGetAuthenticationFlow -f $mskmsiurl)
            if($config.PSObject.Properties.Item('pgid')){
                Write-Warning ("The error was: {0}" -f $config.pgid)
            }
            if($config.PSObject.Properties.Item('strServiceExceptionMessage')){
                Write-Warning $config.strServiceExceptionMessage
            }
        }
    }
}