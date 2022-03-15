Function Connect-Sway{
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
        #Set params
        if(!$PSBoundParameters.ContainsKey('InformationAction')){
            $PSBoundParameters.Add('InformationAction','SilentlyContinue')
        }
        $PSBoundParameters.Add('ClientId','905fcf26-4eb7-48a0-9ff0-8dcc7194b5ba')
        $PSBoundParameters.Add('Scope','openid profile email offline_access')
        $PSBoundParameters.Add('Redirect_Uri','https://sway.office.com/auth/signin')
        $PSBoundParameters.Add('State','https://sway.office.com/my')
        $PSBoundParameters.Add('Url','https://sway.office.com')
    }
    Process{
        $data = Invoke-AuthorizeFormPost @PSBoundParameters
        if($null -ne $data){
            $cookie = $data.Cookies | Where-Object {$_.Name -eq 'AADAuth'}
            if($null -ne $cookie -and $cookie -is [System.Net.Cookie] -and $null -ne $cookie.Value){
                #Write message
                $msg = @{
                    MessageData = ($Script:messages.SuccessfullyConnectedTo -f "Sway portal")
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
            $results.microsoft_Sway = $obj
        }
    }
}