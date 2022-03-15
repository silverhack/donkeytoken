Function Get-OpenIdConfiguration{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$username,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$windows_net
    )
    try{
        if($PSBoundParameters.ContainsKey('windows_net')){
            $endpoint = ('https://login.windows.net/{0}/.well-known/openid-configuration' -f $username.Split('@')[1])
        }
        else{
            $endpoint = ('https://login.microsoftonline.com/{0}/.well-known/openid-configuration' -f $username.Split('@')[1])
        }
        $param = @{
            Url = $endpoint;
            Method = "Get";
            CookieContainer = $cookiejar;
            Verbose = $PSBoundParameters['Verbose']
            Debug = $PSBoundParameters['Debug']
        }
        #Get OpenId Configuration
        $openId_conf = New-WebRequest @param
        if($openId_conf){
            return $openId_conf
        }
        else{
            return $null
        }
    }
    catch{
        Write-Warning ($script:messages.UnableToGetOpenIdInfo -f $username)
        Write-Verbose $_.Exception
        return $null
    }
}