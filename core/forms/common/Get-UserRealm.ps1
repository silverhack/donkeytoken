Function Get-UserRealm{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$username,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$windows_net
    )
    try{
        if($PSBoundParameters.ContainsKey('windows_net')){
            $endpoint = ('https://login.windows.net/getuserrealm.srf?login={0}' -f $username)
        }
        else{
            $endpoint = ('https://login.microsoftonline.com/getuserrealm.srf?login={0}' -f $username)
        }
        $param = @{
            Url = $endpoint;
            Method = "Get";
            CookieContainer = $cookiejar;
            Verbose = $PSBoundParameters['Verbose']
            Debug = $PSBoundParameters['Debug']
        }
        #Get User realm
        $user_realm = New-WebRequest @param
        if($user_realm){
            return $user_realm
        }
        else{
            return $null
        }
    }
    catch{
        Write-Warning ($script:messages.UnableToGetUserRealm -f $username)
        Write-Verbose $_.Exception
        return $null
    }
}