Function Invoke-AuthorizeWithPKCEOrganizations{
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
        [string]$Redirect_Uri
    )
    Begin{
        $config = $null
        $common_config = $null;
        $auth_data = $null;
        $auth_token = $null;
        $flow_auth = $null;
        $auth_response = $null;
        $_TenantId= $null;
        #Getting TenantId or Tenant Name
        if($PSBoundParameters.ContainsKey('TenantId')){
            $_TenantId = $PSBoundParameters.TenantId
        }
        else{
            #Get user's tenant
            $Tenant = Get-TenantFromUser -username $Credential.UserName
            if($null -ne $Tenant -and $Tenant.psobject.properties.Item('TenantId')){
                $_TenantId = $Tenant.TenantId
            }
            else{
                #Set user's tenant based on userName
                $_TenantId = $Credential.UserName.Split('@')[1]
            }
        }
        $cookies=@(
            ("browserId={0}" -f (New-Guid).ToString())
        )
        [uri]$safe_uri = $redirect_uri;
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
            $endpoint = "https://login.microsoftonline.com"
            $path = 'organizations/oauth2/v2.0/authorize?'
            $endpoint = ("{0}/{1}{2}" -f $endpoint, $path, $param)
        }
        $userName = $credential.UserName
        if($userName){
            Set-Variable userName -Value $userName -Scope Script -Force
            #create cookiejar and set script variable
            $cookiejar = New-Object System.Net.CookieContainer 
            Set-Variable cookiejar -Value $cookiejar -Scope Script -Force
        }
    }
    Process{
        if($endpoint){
            $param = @{
                Url = $endpoint;
                Method = "Get";
                CookieContainer = $cookiejar;
                Cookies = $cookies;
                Verbose = $PSBoundParameters['Verbose']
                Debug = $PSBoundParameters['Debug']
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
                $url = 'https://login.windows.net/organizations/oauth2/v2.0/token'
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
                    Content_Type = "application/x-www-form-urlencoded"              
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

