Function Connect-OfficePortal{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [pscredential]$credential,

        # Tenant identifier of the authority to issue token.
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [AllowEmptyString()]
        [string] $TenantId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$GetRawData
    )
    Begin{
        if(!$PSBoundParameters.ContainsKey('InformationAction')){
            $PSBoundParameters.Add('InformationAction','SilentlyContinue')
        }
        $connected = $null
        #Microsoft 365 url
        $office_path = "/?from=PortalHome"
        $office_url = 'https://www.office.com/login?ru='
        $encoded_office_path = [System.Web.HttpUtility]::UrlEncode($office_path)
        #Shell azure url
        $url = ("{0}{1}" -f $office_url, $encoded_office_path)
        #Set url
        $PSBoundParameters.Add('url',$url)
        #Get new parameters
        $new_params = @{}
        foreach ($param in $PSBoundParameters.GetEnumerator()){
            if($param.Key -eq 'GetRawData'){continue}
            $new_params.add($param.Key, $param.Value)
        }
    }
    Process{
        $data = Connect-Microsoft365Portal @new_params
        if($null -ne $data){
            $cookie = $data.Cookies | Where-Object {$_.Name -eq 'OhpAuth'}
            if($null -ne $cookie -and $cookie -is [System.Net.Cookie] -and $null -ne $cookie.Value){
                #Write message
                $msg = @{
                    MessageData = ($Script:messages.SuccessfullyConnectedTo -f "Office Portal")
                    InformationAction = $PSBoundParameters['InformationAction'];
                }
                Write-Information @msg
                $connected = $True
            }
        }
    }
    End{
        if($null -ne (Get-Variable -Name results -ErrorAction Ignore)){
            [pscustomobject]$obj = @{
                Data = $data
            }
            $results.microsoft_portal = $obj
        }
        #Check for raw data
        if($PSBoundParameters.ContainsKey('GetRawData') -and $PSBoundParameters.GetRawData.IsPresent -and $null -ne $connected){
            #Get Raw data
            $raw_data = Get-AuthenticatedResponse -WebResponse $data
            if($raw_data){
                return $raw_data
            }
            else{
                Write-Warning "Unable to get Raw data from Office portal"
            }
        }
    }
}