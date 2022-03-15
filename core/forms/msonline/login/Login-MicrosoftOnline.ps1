Function Login-MicrosoftOnline{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [pscredential]$inputObject,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$user_info,

        [Parameter(Mandatory=$false, HelpMessage="config file")]
        [object]$config,

        [parameter(Mandatory=$false)]
        [string]$TenantId
    )
    Begin{
        $bypassConfig = $raw_login = $null
        #Extract username and password
        $userName = $inputObject.UserName
        $password = $inputObject.GetNetworkCredential().Password
        #Construct body
        if($user_info -and $config){
            $body=@{
                "login" = $userName
                "loginFmt" = $userName
                "i13"="0"
                "type"="11"
                "LoginOptions"="3"
                "passwd"=$password
                "ps"="2"
                "flowToken"=$user_info.FlowToken
                "canary"=$config.canary
                "ctx"=$config.sCtx
                "NewUser"="1"
                "PPSX"=""
                "fspost"="0"
                "hpgrequestid"=(New-Guid).ToString()
            }
            #Set headers
            $headers=@{
                "Upgrade-Insecure-Requests" = "1"
            }
            #convert Body
            $body = ($body.GetEnumerator() | % { "$($_.Key)=$($_.Value)" }) -join '&'
        }
    }
    Process{
        if($body){
            if($PSBoundParameters.ContainsKey('TenantId') -and $PSBoundParameters.TenantId){
                $msOnline_common = ('https://login.microsoftonline.com/{0}/login' -f $TenantId)
            }
            else{
                $msOnline_common = "https://login.microsoftonline.com/common/login"
            }
            #Set params
            $param = @{
                Url = $msOnline_common;
                Method = "Post";
                Data = $body;
                CookieContainer = $cookiejar;
                returnRawResponse = $True;
                Content_Type = 'application/x-www-form-urlencoded';
                Headers= $headers;
                Referer = "https://login.microsoftonline.com/";
                Verbose = $PSBoundParameters['Verbose'];
                Debug = $PSBoundParameters['Debug'];
            }
            $raw_response = New-WebRequest @param
            if($null -ne $raw_response){
                $location = $raw_response.Headers['Location']
            }
            if($null -ne $location){
                if($location -match "device.login.microsoftonline.com"){
                    Write-Verbose "device login detected"
                    $raw_login = Connect-MsDeviceLogin -Url $location
                    $raw_response.Close()
                    $raw_response.Dispose()
                }
                elseif($location -match "#code"){
                    Write-Verbose "Code detected"
                    $bypassConfig = $True
                    $config = $location
                    #Close request
                    $raw_response.Close()
                    $raw_response.Dispose()
                }
            }
            else{
                #Try to get config
                $raw_login = Get-ResponseStream -WebResponse $raw_response
                $raw_response.Close()
                $raw_response.Dispose()
            }
            if($null -eq $bypassConfig){
                #get config
                $config = Get-ConfigFromUrl -inputObject $raw_login
            }
        }
    }
    End{
        if($config){
            return $config
        }
        else{
            Write-Warning ($Script:messages.UnableToGetConfig -f $msOnline_common)
            return $null
        }
    }
}