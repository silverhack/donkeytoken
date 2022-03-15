﻿Function Connect-ToDo{
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
        $PSBoundParameters.Add('ClientId','3ff8e6ba-7dc3-4e9e-ba40-ee12b60d6d48')
        $PSBoundParameters.Add('Scope','openid profile email offline_access')
        $PSBoundParameters.Add('Redirect_Uri','https://to-do.office.com/tasks/auth/callback')
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
            $results.microsoft_ToDo = $obj
        }
    }
}