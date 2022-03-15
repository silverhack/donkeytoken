Function Connect-AzurePortal{
    <# 
     .SYNOPSIS 
     Acquires OAuth AccessToken from Azure Active Directory Web portal
 
     .DESCRIPTION 
     The Connect-AzurePortal function lets you acquire an OAuth AccessToken from Azure web portal by passing
     a PSCredential object with a username and password

     .PARAMETER credential
     PSCredential object
 
     .PARAMETER TenantId
     A registerered TenantId.

     .PARAMETER AADPortal
     Use Azure AAD Portal instead of Azure Portal
 
     .EXAMPLE 
     $Credential = Get-Credential -Message "Please, enter user and password:"
     $access_token = Connect-AzurePortal -credential $Credential
 
     This example acquire an accesstoken by using user&password grant flow.
 
    #>
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [pscredential]$credential,

        [parameter(Mandatory=$false)]
        [string]$TenantId,

        [Parameter(Mandatory=$false, HelpMessage="Use Azure AAD Portal instead of Azure Portal")]
        [Switch]$AADPortal
    )
    Begin{
        #Set to null
        $client_request_id = $config = $auth_data = $auth_token = $login_msonline_url = $null
        if($AADPortal){
            Write-Information "Switching to Azure AD endpoint"
            #Load To AAD Portal
            #$url = "https://aad.portal.azure.com/signin/idpRedirect.js/?feature.settingsportalinstance=&feature.refreshtokenbinding=true&feature.usemsallogin=false&feature.snivalidation=true&feature.setsamesitecookieattribute=true&idpRedirectCount=0"
            #$portal_url = "https://aad.portal.azure.com/signin/index/?feature.refreshtokenbinding=true&feature.snivalidation=true&feature.usemsallogin=false"
            $url = "https://aad.portal.azure.com/signin/idpRedirect.js/"
            $portal_url = "https://aad.portal.azure.com/signin/index/"
        }
        else{
            #Load To Azure Portal
            #$url = "https://portal.azure.com/signin/idpRedirect.js/?feature.settingsportalinstance=&feature.refreshtokenbinding=true&feature.usemsallogin=false&feature.snivalidation=true&feature.setsamesitecookieattribute=true&idpRedirectCount=0"
            #$portal_url = "https://portal.azure.com/signin/index/?feature.refreshtokenbinding=true&feature.snivalidation=true&feature.usemsallogin=false"
            $url = "https://portal.azure.com/signin/idpRedirect.js/"
            $portal_url = "https://portal.azure.com/signin/index/"
        }
        #Extract user and password from pscredentials
        $userName = $credential.UserName
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
            Verbose = $PSBoundParameters['Verbose'];
            Debug = $PSBoundParameters['Debug'];
        }
        $data = New-WebRequest @param
        try{
            #Get cookies from url      
            $cookies = $cookiejar.GetCookies($url)
            #Extract msonline url
            $configPattern = [Regex]::new('https://login.microsoftonline.com.*[^");]')
            $matches = $configPattern.Matches($data)
            $login_msonline_url = $matches[0].Value
            #parse url and get client_id and browser_id
            $parsed_url = [uri]$login_msonline_url
            $ParsedQueryString = [System.Web.HttpUtility]::ParseQueryString($parsed_url.Query)
            $client_request_id = $ParsedQueryString['client-request-id']
            $browser_request_id = $ParsedQueryString['client-request-id']
            Set-Variable client_request_id -Value $client_request_id -Scope Script -Force
        }
        catch{
            Write-Warning "Unable to get Login url from Azure portal"
            Write-Verbose $_.Exception
        }
    }
    Process{
        #Go to MS online and get config
        $cookies=@(
            "x-ms-gateway-slice=004; stsservicecookie=ests; AADSSO=NANoExtension; SSOCOOKIEPULLED=1"
        )
        #Get response data
        $param = @{
            Url = $login_msonline_url;
            Method = "Get";
            CookieContainer = $cookiejar;
            Cookies = $cookies;
            Verbose = $PSBoundParameters['Verbose'];
            Debug = $PSBoundParameters['Debug'];
        }
        $response_msonline = New-WebRequest @param
        #extract config
        $config = Get-ConfigFromUrl -inputObject $response_msonline
        #Get user info
        $userInfo=Get-CredentialType -UserName $userName -config $config
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
            $config = Login-MicrosoftOnline @param
        }
        #Go to KMSI login
        if($null -ne $config -and $config.PSObject.Properties.Item('sFT') -and $config.PSObject.Properties.Item('canary') -and $config.PSObject.Properties.Item('sCtx')){
            $flow_auth = Get-FlowFromKmsi -config $config
            if($flow_auth){
                #Get auth data & cookies from azure Portal
                $param = @{
                    flow_auth= $flow_auth;
                    Verbose = $PSBoundParameters['Verbose'];
                    Debug = $PSBoundParameters['Debug'];
                }
                $auth_data = Connect-Portal @param
            }
        }
        elseif($config.PSObject.Properties.Item('unsafe_strTopMessage')){
            Write-Warning $config.unsafe_strTopMessage
        }
        if($null -ne $auth_data){
            $raw_data = Get-ResponseStream -WebResponse $auth_data
            if($null -ne $raw_data){
                try{
                    $configPattern = [Regex]::new('{"oAuthToken":.*}}')
                    $matches = $configPattern.Matches($raw_data)
                    $auth_token = $matches[0].Value | ConvertFrom-Json
                    $auth_data.Close()
                    $auth_data.Dispose()
                    Write-Information ("Logged as {0}" -f $userName)
                }
                catch{
                    Write-Warning "Unable to get token from Azure Portal"
                    Write-Verbose $_
                }
            }
        }
    }
    End{
        return $auth_token
    }
}