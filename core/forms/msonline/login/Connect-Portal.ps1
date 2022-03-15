Function Connect-Portal{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false, HelpMessage="config file")]
        [object]$flow_auth
    )
    Begin{
        $authenticated_response = $null
        $raw_response = $null
        #convert Body
        $body = ($flow_auth.psobject.properties | Where-Object {$_.name -ne "hidden_form"} | % {("{0}={1}" -f $_.name,$_.Value )}) -join '&'
    }
    Process{
        [uri]$safeUri = $flow_auth.hidden_form
        #Get response
        $param = @{
            Url = $flow_auth.hidden_form;
            Method = "Post";
            Data= $body;
            AllowAutoRedirect= $false;
            Cookies= $cookiejar.GetCookieHeader('https://{0}' -f $safeUri.Authority);#$cookiejar.GetCookieHeader("https://login.microsoftonline.com");#$office_cookies;
            CookieContainer= $cookiejar;
            returnRawResponse= $true;
            Referer = "https://login.microsoftonline.com/";
            Content_Type = "application/x-www-form-urlencoded";
            Verbose = $PSBoundParameters['Verbose'];
            Debug = $PSBoundParameters['Debug'];
        }
        $response = New-WebRequest @param
    }
    End{
        if($response){
            return $response
        }
    }
}