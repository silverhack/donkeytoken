Function Invoke-AuthorizeFormPost{
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
        [string]$Url,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$State,

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
        #create cookiejar and set script variable
        $cookiejar = New-Object System.Net.CookieContainer 
        Set-Variable cookiejar -Value $cookiejar -Scope Script -Force
        #main endpoint
        $ms_host = 'https://login.microsoftonline.com'
        #Set cookies
        $cookies=@(
            ("browserId={0}" -f (New-Guid).ToString())
        )
        #Set url
        [uri]$safe_uri = $Redirect_Uri;
        #Get Nonce from first query
        $param = @{
            Url = $Url;
            Method = "Get";
            CookieContainer = $cookiejar;
            Cookies = $cookies;
            AllowAutoRedirect= $true;
            returnRawResponse = $True;
            Verbose = $PSBoundParameters['Verbose']
            Debug = $PSBoundParameters['Debug']
        }
        $response = New-WebRequest @param
        #Get nonce value
        $nonce = $cookiejar.GetCookies("https://{0}" -f $safe_uri.Authority.ToString()) | Where-Object {$_.Name -eq 'AADNonce'} | Select-Object -ExpandProperty Value
        #Close the response
        $response.Close()
        #Dispose
        $response.Dispose()
        if($nonce){
            $raw_param = [ordered]@{
                client_id = $ClientId;
                scope = [System.Web.HttpUtility]::UrlEncode($Scope);
                redirect_uri = [System.Web.HttpUtility]::UrlEncode($Redirect_Uri);
                "client-request-id" = (New-Guid).ToString()
                response_mode = "form_post";
                response_type = [System.Web.HttpUtility]::UrlEncode("id_token code");
                nonce = $nonce;
                state = $State;
            }
            $param = ($raw_param.GetEnumerator() | % {("{0}={1}" -f $_.name,$_.Value )}) -join '&'
            if($PSBoundParameters.ContainsKey('TenantId') -and $PSBoundParameters.TenantId){
                $path = ('{0}/oauth2/authorize?' -f $PSBoundParameters.TenantId)
            }
            else{
                $path = 'common/oauth2/authorize?'
            }
            $endpoint = ("https://login.microsoftonline.com/{0}{1}" -f $path, $param)
        }
    }
    Process{
        if($endpoint){
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
        if($null -ne $common_config){
            #Go to KMSI login
            $flow_auth = Get-FlowFromKmsi -config $common_config
            if($flow_auth){
                #Get auth data & cookies from azure shell
                $param = @{
                    flow_auth= $flow_auth
                }
                $auth_data = Connect-Portal @param
            }
        }
    }
    End{
        if($null -ne $auth_data){
            return $auth_data
        }
    }
}


