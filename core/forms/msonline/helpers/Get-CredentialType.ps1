# Return user's auth type
function Get-CredentialType{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$UserName,
        [Parameter(Mandatory=$False)]
        [object]$config

    )
    Begin{
        $credType_url = $user_realm = $null
        if($null -ne $config -and $config.Psobject.Properties.Item('urlGetCredentialType')){
            $credType_url = $config.urlGetCredentialType
        }
    }
    Process{
        if($null -ne $config -and $config.Psobject.Properties.Item('sFT')){
            # construct body
            $body = @{
                "username"=$UserName
                "flowToken"=$config.sFT
            }
            #convert JSON
            $body = $body | ConvertTo-Json
        }
        if($null -ne $credType_url){
            #Get realm
            $param = @{
                Url = $credType_url;
                Method = "Post";
                CookieContainer= $cookiejar;
                Content_Type  = "application/json; charset=UTF-8";
                Data = $body;
                Verbose = $PSBoundParameters['Verbose'];
                Debug = $PSBoundParameters['Debug'];
            }
            $user_realm = New-WebRequest @param
        }
    }
    End{
        if($user_realm){
            return $user_realm
        }
        else{
            Write-Warning ("Unable to get user's realm")
            return $null
        }
    }
}