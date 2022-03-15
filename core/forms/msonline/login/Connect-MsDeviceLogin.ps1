Function Connect-MsDeviceLogin{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Url
    )
    Begin{
        $post_request = $null;
        #Create new request
        $param = @{
            Url = $Url;
            Method = "Get";
            CookieContainer = $cookiejar;
            Content_Type = 'application/x-www-form-urlencoded';
            Headers= $headers;
            Referer = "https://login.microsoftonline.com/";
            Verbose = $PSBoundParameters['Verbose'];
            Debug = $PSBoundParameters['Debug'];
        }
        [xml]$raw_request = New-WebRequest @param
    }
    Process{
        if($raw_request){
            #Get code, id_token... from xml data
            $hidden_form = $raw_request.SelectSingleNode("//form[@name='hiddenform']").action
            $ctx = $raw_request.SelectSingleNode("//input[@name='ctx']").value
            $flowtoken = $raw_request.SelectSingleNode("//input[@name='flowtoken']").value
            $auth_flow = New-Object -TypeName PSCustomObject
            $auth_flow | Add-Member -type NoteProperty -name hidden_form -value $hidden_form
            $auth_flow | Add-Member -type NoteProperty -name ctx -value $ctx
            $auth_flow | Add-Member -type NoteProperty -name flowtoken -value $flowtoken
            #convert Body
            $body = ($auth_flow.psobject.properties | Where-Object {$_.name -ne "hidden_form"} | % {("{0}={1}" -f $_.name,$_.Value )}) -join '&'
            [uri]$safeUri = $auth_flow.hidden_form
            #Get response
            $param = @{
                Url = $auth_flow.hidden_form;
                Method = "Post";
                Data= $body;
                AllowAutoRedirect= $false;
                Cookies= $cookiejar.GetCookieHeader('https://{0}' -f $safeUri.Authority);
                CookieContainer= $cookiejar;
                Referer = "https://login.microsoftonline.com/";
                Content_Type = "application/x-www-form-urlencoded";
                Verbose = $PSBoundParameters['Verbose'];
                Debug = $PSBoundParameters['Debug'];
            }
            $post_request = New-WebRequest @param  
        }
    }
    End{
        if($post_request){
            return $post_request
        }
    }
}