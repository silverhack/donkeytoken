Function Connect-ExchangeEWS{
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
        $response = $connected = $null
        $basicAuth = Get-BasicAuthenticationHeader -credential $credential
        $endpoint = 'https://outlook.office365.com/EWS/Exchange.asmx'
        if($null -ne $basicAuth){
            $param = @{
                Url = $endpoint;
                Method = "Get";
                Headers = $basicAuth;
                returnRawResponse = $True;
                Verbose = $PSBoundParameters['Verbose']
                Debug = $PSBoundParameters['Debug']
            }
            $response = New-WebRequest @param
        }
    }
    Process{
        if($null -ne $response -and $response.StatusCode.value__ -eq 200){
            #Write message
            $msg = @{
                MessageData = ($Script:messages.SuccessfullyConnectedTo -f "Exchange Web Services")
                InformationAction = $PSBoundParameters['InformationAction'];
            }
            Write-Information @msg
            $connected = $True
        }
    }
    End{
        if($null -ne (Get-Variable -Name results -ErrorAction Ignore)){
            [pscustomobject]$obj = @{
                Data = $response
            }
            $results.exchange_web_services = $obj
        }
        #Check for raw data
        if($PSBoundParameters.ContainsKey('GetRawData') -and $PSBoundParameters.GetRawData.IsPresent -and $null -ne $connected){
            #Get Raw data
            $raw_data = Get-ResponseStream -WebResponse $response
            if($raw_data){
                return $raw_data
            }
            else{
                Write-Warning "Unable to get Raw data from Exchange web services"
            }
        }
    }
}