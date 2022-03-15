Function Get-TokenForResource{
    [CmdletBinding()]
    Param (
        # pscredential of the application requesting the token
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [System.Management.Automation.PSCredential] $credential,

        # Tenant identifier of the authority to issue token.
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [AllowEmptyString()]
        [string] $TenantId
    )
    #Get InformationAction
    if($PSBoundParameters.ContainsKey('InformationAction')){
        $informationAction = $PSBoundParameters.informationAction
    }
    else{
        $informationAction = "SilentlyContinue"
    }
    try{
        foreach($endpoint in $endpoints){
            $param = @{
                Credential = $credential;
                TenantId = $TenantId;
                ClientId = $endpoint.ClientId;
                Resource = $endpoint.resource;
                InformationAction = $informationAction;
                Verbose = $PSBoundParameters['Verbose'];
                Debug = $PSBoundParameters['Debug'];
            }
            $access_token = Get-MSAuthToken @param
            if($null -ne $access_token){
                #Write message
                $msg = @{
                    MessageData = ($Script:messages.SuccessfullyConnectedTo -f $endpoint.FriendlyName)
                    InformationAction = $informationAction;
                }
                Write-Information @msg
                if($null -ne (Get-Variable -Name results -ErrorAction Ignore)){
                    [pscustomobject]$obj = @{
                        Data = $access_token
                    }
                    [void]$results.Add($endpoint.FriendlyName.Replace(' ','').Tolower(),$obj)
                }
            }
            else{
                #Write message
                Write-Warning -Message ($Script:messages.UnableToGetToken -f $endpoint.FriendlyName)
                #return $null
            }
        }
    }
    catch{
        Write-Verbose $_
    }
}