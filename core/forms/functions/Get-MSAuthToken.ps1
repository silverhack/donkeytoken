Function Get-MSAuthToken{
    <# 
     .SYNOPSIS 
     Acquires OAuth AccessToken from microsoft online
 
     .DESCRIPTION 
     The Get-MSAuthToken function lets you acquire an OAuth AccessToken from microsoft online by passing
     a PSCredential object with a username and password

     .PARAMETER credential
     PSCredential object
 
     .PARAMETER TenantId
     A registerered TenantId.

     .PARAMETER clientId
     A registerered ApplicationID as application to the Azure Active Directory.

     .PARAMETER Resource
     Target resource.
 
     .EXAMPLE 
     $Credential = Get-Credential -Message "Please, enter user and password:"
     $access_token = Get-MSAuthToken -credential $Credential
 
     This example acquire an accesstoken by using user&password grant flow.

     .EXAMPLE 
     $Credential = Get-Credential -Message "Please, enter user and password:"
     $access_token = Get-MSAuthToken -credential $Credential -Resource "https://graph.microsoft.com"
 
     This example acquire a valid access token for graph.microsoft.com by using user&password grant flow.
 
    #>
    [cmdletbinding()]
    Param(
        [parameter(Mandatory=$true)]
        [pscredential]$Credential,

        [parameter(Mandatory=$false)]
        [string]$TenantId,

        [parameter(Mandatory=$false)]
        [string]$ClientId ="1950a258-227b-4e31-a9cf-717495945fc2",

        [parameter(Mandatory=$false)]
        [string]$Resource = 'management.azure.com',

        [parameter(Mandatory=$false, ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$windows_net
    )
    Begin{
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $_TenantId = $auth_response = $null
        #Getting TenantId or Tenant Name
        if($PSBoundParameters.ContainsKey('TenantId')){
            $_TenantId = $PSBoundParameters.TenantId
        }
        else{
            #Get user's tenant
            $Tenant = Get-TenantFromUser -username $Credential.UserName
            if($null -ne $Tenant -and $Tenant.psobject.properties.Item('TenantId')){
                $_TenantId = $Tenant.TenantId
            }
            else{
                #Set user's tenant based on userName
                $_TenantId = $Credential.UserName.Split('@')[1]
            }
        }
        #Check if use windows.net or microsoftonline
        if($PSBoundParameters.ContainsKey('windows_net')){
            $ms_host = 'https://login.windows.net'
        }
        else{
            $ms_host = 'https://login.microsoftonline.com'
        }
        #Check if _TenantId
        if($null -ne $_TenantId){
            $endpoint = ('{0}/{1}/oauth2/v2.0/token' -f $ms_host, $_TenantId)
        }
        else{
            $endpoint = $null;            
        }
    }
    Process{
        if($null -ne $endpoint){
            if([guid]::TryParse($Resource, $([ref][guid]::Empty))){
                $Resource = ("{0}/.default" -f $Resource)
            }
            elseif($Resource -notmatch "https://"){
                $Resource = ("https://{0}/.default" -f $Resource)
            }
            else{
                $Resource = ("{0}/.default" -f $Resource)
            }
            #Set scope
            $scope = ("openid profile offline_access {0}" -f $Resource)
            #Set Body
            $raw_body = [ordered]@{
                client_id = $clientId;
                client_info = "1";
                scope = [System.Web.HttpUtility]::UrlEncode($scope);
                grant_type= 'password';
                username = $credential.UserName;
                password = $credential.GetNetworkCredential().Password;
            }
            $body = ($raw_body.GetEnumerator() | % {("{0}={1}" -f $_.name,$_.Value )}) -join '&'
            #Get response
            $param = @{
                Url = $endpoint;
                Method = "Post";
                Data= $body;
                Referer = $ms_host;
                Content_Type = "application/x-www-form-urlencoded";
                Verbose = $PSBoundParameters['Verbose'];
                Debug = $PSBoundParameters['Debug'];
            }
            $auth_response = New-WebRequest @param
        }
    }
    End{
        if($null -ne $auth_response){
            return $auth_response
        }
        else{
            return $null
        }
    }
}