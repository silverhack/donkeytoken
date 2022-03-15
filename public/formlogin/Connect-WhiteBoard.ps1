Function Connect-WhiteBoard{
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
        $PSBoundParameters.Add('ClientId','95de633a-083e-42f5-b444-a4295d8e9314')
        $PSBoundParameters.Add('Scope','openid profile email offline_access')
        $PSBoundParameters.Add('Redirect_Uri','https://app.whiteboard.microsoft.com/msalredirect/')
    }
    Process{
        $data = Invoke-AuthorizeWithPKCE @PSBoundParameters
        if($null -ne $data -and $null -ne $data.psobject.properties.Item('access_token')){
            #Write message
            $msg = @{
                MessageData = ($Script:messages.SuccessfullyConnectedTo -f "Microsoft ToDo portal")
                InformationAction = $PSBoundParameters['InformationAction'];
            }
            Write-Information @msg
        }
    }
    End{
        if($null -ne (Get-Variable -Name results -ErrorAction Ignore)){
            [pscustomobject]$obj = @{
                Data = $data
            }
            $results.microsoft_whiteboard = $obj
        }
    }
}