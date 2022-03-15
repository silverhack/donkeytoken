Function Connect-MySignInAccess{
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
        $PSBoundParameters.Add('ClientId','19db86c3-b2b9-44cc-b339-36da233a3be2')
        $PSBoundParameters.Add('Scope','openid profile email offline_access')
        $PSBoundParameters.Add('Redirect_Uri','https://mysignins.microsoft.com')
    }
    Process{
        $data = Invoke-AuthorizeWithPKCE @PSBoundParameters
        if($null -ne $data -and $null -ne $data.psobject.properties.Item('access_token')){
            #Write message
            $msg = @{
                MessageData = ($Script:messages.SuccessfullyConnectedTo -f "My SignIn portal")
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
            $results.microsoft_mysignin = $obj
        }
    }
}