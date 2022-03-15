Function Connect-OfficeCalendar{
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
        $url = "https://outlook.office.com/calendar/?authRedirect=true&state=0"
        #Set url
        $PSBoundParameters.Add('url',$url)
    }
    Process{
        $data = Connect-Microsoft365Portal @PSBoundParameters
        if($null -ne $data){
            $cookie = $data.Cookies | Where-Object {$_.Name -eq 'OpenIdConnect.id_token.v1'}
            if($null -ne $cookie -and $cookie -is [System.Net.Cookie] -and $null -ne $cookie.Value){
                #Write message
                $msg = @{
                    MessageData = ($Script:messages.SuccessfullyConnectedTo -f "Calendar")
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
            $results.microsoft_calendar = $obj
        }
    }
}