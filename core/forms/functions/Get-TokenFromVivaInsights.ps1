Function Get-TokenFromVivaInsights{
    <# 
     .SYNOPSIS 
     Acquires OAuth AccessToken from Viva Insights application
 
     .DESCRIPTION 
     The Get-TokenFromVivaInsights function lets you acquire a valid OAuth AccessToken from Outlook API by passing
     a PSCredential object with a username and password

     .PARAMETER credential
     PSCredential object
 
     .PARAMETER TenantId
     A registerered TenantId.
 
     .EXAMPLE 
     $Credential = Get-Credential -Message "Please, enter user and password:"
     $access_token = Get-TokenFromVivaInsights -credential $Credential
 
     This example acquire an Outlook access tokens by using user&password grant flow.
 
    #>
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [pscredential]$credential,

        [parameter(Mandatory=$false)]
        [string]$TenantId
    )
    Begin{
        $config = $url_location = $common_config = $auth_data = $auth_token = $null
        [uri]$safeUri = "https://insights.viva.office.com/"
        $url = "https://insights.viva.office.com/"
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
            #viva endpoint
            $endpoint = ("https://{0}/api/auth/me" -f $auth_data.ResponseUri.Authority)
            #Get location
            $url_location = $auth_data.ResponseUri.OriginalString
            #Get cookies
            $viva_cookies = $cookiejar.GetCookieHeader("https://{0}" -f $auth_data.ResponseUri.Authority) #$response.Headers['Set-cookie']
            #Close the response
            $auth_data.Close()
            #Dispose
            $auth_data.Dispose()
            #Get Me
            $param = @{
                Url = $endpoint;
                Method = "Get";
                CookieContainer = $cookiejar;
                Cookies = $viva_cookies;
                AllowAutoRedirect= $false;
                returnRawResponse = $false;
                Verbose = $PSBoundParameters['Verbose']
                Debug = $PSBoundParameters['Debug']
            }
            $response = New-WebRequest @param
        }
        return $response
    }
}


#$auth = Connect-VivaInsights -credential $credential -Verbose -Debug -InformationAction Continue