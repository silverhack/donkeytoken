Function Connect-WebShell{
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
        #Set params
        $PSBoundParameters.Add('ClientId','89bee1f7-5e6e-4d8a-9f3d-ecd601259da7')
        $PSBoundParameters.Add('Scope','openid profile email offline_access https://graph.microsoft.com/.default')
        $PSBoundParameters.Add('Redirect_Uri','https://webshell.suite.office.com/iframe/TokenFactoryIframe')
    }
    Process{
        $data = Invoke-AuthorizeWithPKCEOrganizations @PSBoundParameters
        if($null -ne $data -and $null -ne $data.psobject.properties.Item('access_token')){
            #Write message
            $msg = @{
                MessageData = ($Script:messages.SuccessfullyConnectedTo -f "WebShell portal")
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
            $results.microsoft_WebShell = $obj
        }
    }
}