Function Invoke-AuthorizeWithPKCE{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [pscredential]$Credential,

        [parameter(Mandatory=$false)]
        [string]$TenantId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$ClientId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$Scope,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$Redirect_Uri,

        [parameter(Mandatory=$false, ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$windows_net,

        [parameter(Mandatory=$false, ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$authenticated
    )
    Begin{
        $config = $common_config = $auth_data = $auth_token = $flow_auth = $auth_response = $_TenantId = $endpoint = $null
        #Check if use windows.net or microsoftonline
        if($PSBoundParameters.ContainsKey('windows_net')){
            $ms_host = 'https://login.windows.net'
        }
        else{
            $ms_host = 'https://login.microsoftonline.com'
        }
        $cookies=@(
            ("browserId={0}" -f (New-Guid).ToString())
        )
        [uri]$safe_uri = $Redirect_Uri;
        $pkce_flow = New-PKCEFlow
        if($null -ne $pkce_flow){
            $raw_param = [ordered]@{
                client_id = $ClientId;
                scope = [System.Web.HttpUtility]::UrlEncode($Scope);
                redirect_uri = [System.Web.HttpUtility]::UrlEncode($Redirect_Uri);
                "client-request-id" = (New-Guid).ToString()
                response_mode = "fragment";
                response_type = 'code';
                code_challenge = $pkce_flow.code_challengue;
                code_challenge_method= 'S256';
                prompt = 'select_account';
            }
            $param = ($raw_param.GetEnumerator() | % {("{0}={1}" -f $_.name,$_.Value )}) -join '&'
            if($PSBoundParameters.ContainsKey('TenantId') -and $PSBoundParameters.TenantId){
                $path = ('{0}/oauth2/v2.0/authorize?' -f $PSBoundParameters.TenantId)
            }
            else{
                $path = 'common/oauth2/v2.0/authorize?'
            }
            #$endpoint = ("https://nexus.microsoftonline-p.com/{0}{1}" -f $path, $param)
            $endpoint = ("{0}/{1}{2}" -f $ms_host, $path, $param)
        }
        $userName = $credential.UserName
        if($userName){
            Set-Variable userName -Value $userName -Scope Script -Force
            if(!$authenticated.IsPresent){
                #create cookiejar and set script variable
                $cookiejar = New-Object System.Net.CookieContainer 
                Set-Variable cookiejar -Value $cookiejar -Scope Script -Force
            }
        }
    }
    Process{
        if($null -ne $endpoint){
            $param = @{
                Url = $endpoint;
                Method = "Get";
                CookieContainer = $cookiejar;
                Cookies = $cookies;
                Verbose = $PSBoundParameters['Verbose'];
                Debug = $PSBoundParameters['Debug'];
            }
            #Go to msonline from location attribute
            $msonline_response = New-WebRequest @param
            #extract config from response
            $config = Get-ConfigFromUrl -inputObject $msonline_response
            if($null -ne $config){
                #Get user info
                $userInfo = Get-CredentialType -UserName $userName -config $config
                if($userInfo){
                    #Login to common and extract config
                    $param = @{
                        inputObject = $credential;
                        config = $config;
                        user_info = $userInfo;
                        TenantId = $PSBoundParameters['TenantId'];
                        Verbose = $PSBoundParameters['Verbose'];
                        Debug = $PSBoundParameters['Debug'];
                    }
                    $common_config = Login-MicrosoftOnline @param
                }
            }
        }
        if($null -ne $common_config -and $common_config -notmatch "#code"){
            #Go to KMSI login
            $flow_auth = Get-RedirectFromKmsi -config $common_config
        }
        else{
            $flow_auth = $common_config
        }
        if($null -ne $flow_auth){
            if($flow_auth -is [System.Net.HttpWebResponse]){
                #Get code
                $code = $flow_auth.ResponseUri.Fragment.Split('&')[0].split('=')[1].ToString()
                $flow_auth.Close()
                $flow_auth.Dispose()
            }
            elseif($flow_auth -is [System.String]){
                #Probably mobile User-Agent. Try to get code
                [uri]$flow = $flow_auth
                $code = $flow.Fragment.Split('&')[0].split('=')[1].ToString()
            }
            else{
                Write-Verbose "Unknown response"
                $code = $null
            }
            if($code){
                $param = [ordered]@{
                    client_id = $clientId;
                    redirect_uri = [System.Web.HttpUtility]::UrlEncode($redirect_uri);
                    scope = [System.Web.HttpUtility]::UrlEncode($scope);
                    code = $code;
                    grant_type = 'authorization_code';
                    code_verifier = $pkce_flow.code_verifier;
                }
                #convert Body
                $body = ($param.GetEnumerator() | % {("{0}={1}" -f $_.name,$_.Value )}) -join '&'
                if($null -ne $_TenantId){
                    $url = ('{0}/{1}/oauth2/v2.0/token' -f $ms_host, $_TenantId)
                }
                else{
                    $url = ('{0}/common/oauth2/v2.0/token' -f $ms_host)
                }
                $headers=@{
                    "Origin" = ("https://{0}" -f $safe_uri.Host)
                }
                #Get response
                $param = @{
                    Url = $url;
                    Method = "Post";
                    Data= $body;
                    AllowAutoRedirect= $false;
                    Headers = $headers;
                    CookieContainer= $cookiejar;
                    returnRawResponse= $false;
                    Referer = "https://login.microsoftonline.com/";
                    Content_Type = "application/x-www-form-urlencoded";
                    Verbose = $PSBoundParameters['Verbose'];
                    Debug = $PSBoundParameters['Debug'];
                }
                $auth_response = New-WebRequest @param
            }
        }
    }
    End{
        if($null -ne $auth_response){
            return $auth_response
        }
    }
}