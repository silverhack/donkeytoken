Function Get-TokenFromToDo{
    <# 
     .SYNOPSIS 
     Acquires OAuth AccessToken from Todo portal
 
     .DESCRIPTION 
     The Get-TokenFromToDo function lets you acquire a valid OAuth AccessToken from resource by passing
     a PSCredential object with a username and password

     .PARAMETER credential
     PSCredential object
 
     .PARAMETER TenantId
     A registerered TenantId.

     .PARAMETER Resource
     Target resource.
 
     .EXAMPLE 
     $Credential = Get-Credential -Message "Please, enter user and password:"
     $access_token = Get-TokenFromToDo -credential $Credential
 
     This example acquire an accesstoken by using user&password grant flow.

     .EXAMPLE 
     $Credential = Get-Credential -Message "Please, enter user and password:"
     $access_token = Get-TokenFromToDo -credential $Credential -Resource "https://graph.microsoft.com"
 
     This example acquire a valid access token for graph.microsoft.com by using user&password grant flow.
 
    #>
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [pscredential]$credential,

        # Tenant identifier of the authority to issue token.
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [AllowEmptyString()]
        [string] $TenantId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$resource = "https://graph.microsoft.com/"
    )
    Begin{
        $_tid = $new_location = $raw_response = $canary = $null
        #Get new parameters
        $param = @{
            Credential = $credential;
            ClientId = "3ff8e6ba-7dc3-4e9e-ba40-ee12b60d6d48";
            Scope= 'openid profile email offline_access';
            Redirect_Uri = "https://to-do.office.com/tasks/auth/callback";
            Verbose = $PSBoundParameters['Verbose'];
            Debug = $PSBoundParameters['Debug'];
            InformationAction = $PSBoundParameters['InformationAction'];
        }
        $token = Invoke-AuthorizeWithPKCE @param
    }
    Process{
        if($null -ne $token){
            $scp = ("openid profile email offline_access {0}/.default" -f $resource)
            $raw_body = [ordered]@{
                client_id = "3ff8e6ba-7dc3-4e9e-ba40-ee12b60d6d48";
                scope  = [System.Web.HttpUtility]::UrlEncode($scp);
                grant_type = "refresh_token";
                refresh_token= $token.refresh_token;
            }
            $endpoint = 'https://login.microsoftonline.com/common/oauth2/v2.0/token'
            $body = ($raw_body.GetEnumerator() | % {("{0}={1}" -f $_.name,$_.Value )}) -join '&'
            #Set headers
            $headers=@{
                "Upgrade-Insecure-Requests" = "1"
                "Sec-Fetch-Dest" = "empty"
                "Sec-Fetch-Mode" = "cors"
                "Sec-Fetch-Site" = "same-origin"
                "Origin" = "https://to-do.office.com"
            }
            #Execute query
            if($null -ne $headers){
                $param = @{
                    Url = $endpoint;
                    Method = "Post";
                    Content_Type = "application/x-www-form-urlencoded";
                    Data = $body;
                    Headers= $headers;
                    Verbose = $PSBoundParameters['Verbose'];
                    Debug = $PSBoundParameters['Debug'];
                }
                $raw_response = New-WebRequest @param
            }
        }
    }
    End{
        if($null -ne $raw_response -and $raw_response.psobject.Properties.Item('token_type')){
            return $raw_response    
        }
        else{
            Write-Warning ("Unable to get an access token for {0}" -f $resource)
        }
    }
}
