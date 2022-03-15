Function Connect-OneDrive{
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
        #Sharepoint url
        $SharepointUrl = ("https://{0}-my.sharepoint.com" -f $credential.UserName.Split('@')[1].Split('.')[0])
        #Set url
        $PSBoundParameters.Add('url',$SharepointUrl)
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
            $cookie = $data.Cookies | Where-Object {$_.Name -eq 'FedAuth'}
            if($null -ne $cookie -and $cookie -is [System.Net.Cookie] -and $null -ne $cookie.Value){
                #Write message
                $msg = @{
                    MessageData = ($Script:messages.SuccessfullyConnectedTo -f "OneDrive for business")
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
            $results.onedrive = $obj
        }
        #Check for raw data
        if($PSBoundParameters.ContainsKey('GetRawData') -and $PSBoundParameters.GetRawData.IsPresent -and $null -ne $connected){
            #Get Raw data
            $raw_data = Get-AuthenticatedResponse -WebResponse $data
            if($raw_data){
                return $raw_data
            }
            else{
                Write-Warning "Unable to get Raw data from OneDrive for business"
            }
        }
    }
}