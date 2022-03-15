Function Connect-Microsoft365Portal{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [pscredential]$credential,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$url,

        [parameter(Mandatory=$false)]
        [string]$TenantId
    )
    Begin{
        $config = $url_location = $common_config = $auth_data = $auth_token = $null
        [uri]$safeUri = $url
        #Extract user and password from pscredentials
        $userName = $credential.UserName
        if($userName){
            Set-Variable userName -Value $userName -Scope Script -Force
            #create cookiejar and set script variable
            $cookiejar = New-Object System.Net.CookieContainer 
            Set-Variable cookiejar -Value $cookiejar -Scope Script -Force
            $cookies=@(
                ("browserId={0}" -f (New-Guid).ToString())
            )
            #Request
            $param = @{
                Url = $url;
                Method = "Get";
                CookieContainer = $cookiejar;
                Cookies = $cookies;
                AllowAutoRedirect= $true;
                returnRawResponse = $True;
                Verbose = $PSBoundParameters['Verbose']
                Debug = $PSBoundParameters['Debug']
            }
            $response = New-WebRequest @param
            if($null -ne $response){
                #Get location
                $url_location = $response.ResponseUri.OriginalString
                #Get cookies
                $office_cookies = $cookiejar.GetCookieHeader("https://{0}" -f $safeUri.Authority) #$response.Headers['Set-cookie']
                #Close the response
                $response.Close()
                #Dispose
                $response.Dispose()
            }
        }
    }
    Process{
        if($url_location){
            $param = @{
                Url = $url_location;
                Method = "Get";
                CookieContainer = $cookiejar;
                Cookies = $cookies;
                Verbose = $PSBoundParameters['Verbose']
                Debug = $PSBoundParameters['Debug']
            }
            #Go to msonline from location attribute
            $msonline_response = New-WebRequest @param
            #return $msonline_response
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