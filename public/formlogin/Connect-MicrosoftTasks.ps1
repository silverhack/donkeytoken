﻿Function Connect-MicrosoftTasks{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [pscredential]$credential,

        # Tenant identifier of the authority to issue token.
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [AllowEmptyString()]
        [string] $TenantId
    )
    Begin{
        if(!$PSBoundParameters.ContainsKey('InformationAction')){
            $PSBoundParameters.Add('InformationAction','SilentlyContinue')
        }
        $office_path = "/landing&mkt=en-US"
        $office_tasks_url = 'https://tasks.office.com/oidcLogin?ru='
        $encoded_office_path = [System.Web.HttpUtility]::UrlEncode($office_path)
        #Shell azure url
        $url = ("{0}{1}" -f $office_tasks_url, $encoded_office_path)
        #Set url
        $PSBoundParameters.Add('url',$url)
    }
    Process{
        $data = Connect-Microsoft365Portal @PSBoundParameters
        if($null -ne $data){
            $cookie = $data.Cookies | Where-Object {$_.Name -eq 'plannerauth-oidc'}
            if($null -ne $cookie -and $cookie -is [System.Net.Cookie] -and $null -ne $cookie.Value){
                #Write message
                $msg = @{
                    MessageData = ($Script:messages.SuccessfullyConnectedTo -f "Microsoft Tasks")
                    InformationAction = $PSBoundParameters['InformationAction'];
                }
                Write-Information @msg
            }
        }
    }
    End{
        if($null -ne (Get-Variable -Name results -ErrorAction Ignore)){
            [pscustomobject]$obj = @{
                Data = $data
            }
            $results.microsoft_tasks = $obj
        }
    }
}