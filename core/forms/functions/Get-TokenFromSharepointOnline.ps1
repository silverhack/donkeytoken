Function Get-TokenFromSharepointOnline{
    <# 
     .SYNOPSIS 
     Acquires OAuth AccessToken from Sharepoint Online 
 
     .DESCRIPTION 
     The Get-TokenFromSharepointOnline function lets you acquire a valid OAuth AccessToken from Sharepoint Online by passing
     a PSCredential object with a username and password

     .PARAMETER credential
     PSCredential object
 
     .PARAMETER TenantId
     A registerered TenantId.

     .PARAMETER Resource
     Target resource.
 
     .EXAMPLE 
     $Credential = Get-Credential -Message "Please, enter user and password:"
     $access_token = Get-TokenFromSharepointOnline -credential $Credential
 
     This example acquire an accesstoken by using user&password grant flow.

     .EXAMPLE 
     $Credential = Get-Credential -Message "Please, enter user and password:"
     $access_token = Get-TokenFromSharepointOnline -credential $Credential -Resource "https://graph.microsoft.com"
 
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
        $raw_context = $raw_response = $null
        if(!$PSBoundParameters.ContainsKey('InformationAction')){
            $PSBoundParameters.Add('InformationAction','SilentlyContinue')
        }
        #Sharepoint url
        $SharepointUrl = ("https://{0}.sharepoint.com" -f $credential.UserName.Split('@')[1].Split('.')[0])
        [uri]$safeUri = $SharepointUrl
        #Get new parameters
        $new_params = @{}
        foreach ($param in $PSBoundParameters.GetEnumerator()){
            if($param.Key -eq 'resource'){continue}
            $new_params.add($param.Key, $param.Value)
        }
        #Connect SharepointOnline
        $data = Connect-SharepointOnline @new_params -GetRawData
        #Get Context
        if($null -ne $data){
            Write-Verbose $Script:messages.GetContextFromSPS
            #Set headers
            $headers=@{
                    "Odata-Version" = "4.0"
            }
            $param = @{
                Url = ("{0}/_api/contextinfo" -f $SharepointUrl);
                Method = "Post";
                Cookies= $cookiejar.GetCookieHeader('https://{0}' -f $safeUri.Authority);
                Encoding = 'application/json;odata.metadata=minimal';
                Content_Type = 'application/json;charset=utf-8';
                Headers = $headers;
                CookieContainer = $cookiejar;
                Verbose = $PSBoundParameters['Verbose'];
                Debug = $PSBoundParameters['Debug'];
            }
            $raw_context = New-WebRequest @param
        }
    }
    Process{
        if($null -ne $raw_context){
            [uri]$safeUri = $SharepointUrl
            #Post Data
            $rsrc = [ordered]@{
                resource = $resource;
            } | ConvertTo-Json -Depth 2 -Compress
            #Set headers
            $headers=@{
                "X-RequestDigest" = $raw_context.FormDigestValue;
                "Odata-Version" = "4.0"
            }
            #Execute query
            $param = @{
                Url = ("{0}/_api/SP.OAuth.Token/Acquire" -f $SharepointUrl);
                Method = "Post";
                Data = $rsrc;
                Headers = $headers
                Encoding = 'application/json;odata.metadata=minimal';
                Content_Type = 'application/json;charset=utf-8';
                Cookies= $cookiejar.GetCookieHeader('https://{0}' -f $safeUri.Authority);
                CookieContainer = $cookiejar;
                Verbose = $PSBoundParameters['Verbose'];
                Debug = $PSBoundParameters['Debug'];
            }
            $raw_response = New-WebRequest @param
        }
    }
    End{
        return $raw_response
    }
}