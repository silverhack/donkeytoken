function Get-DelegationTokenFromAzurePortal{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$false)]
        [pscredential]$credential,

        [parameter(Mandatory=$false)]
        [string]$TenantId,

        [parameter(Mandatory= $false, HelpMessage= "Token type")]
        [ValidateSet("self","graph","microsoft.graph","office")]
        [String]$token_type= "graph",

        [parameter(Mandatory= $false, HelpMessage= "Extension type")]
        [ValidateSet("Microsoft_AAD_IAM","Microsoft_Intune_Devices","Microsoft_Intune_Workflows",
                     "Microsoft_Intune_Apps","Microsoft_Intune_DeviceSettings","Microsoft_Intune")]
        [String]$extension_type= "fx",

        [Parameter(Mandatory=$false, HelpMessage="Use Azure AAD Portal instead of Azure Portal")]
        [Switch]$AADPortal
    )
    Begin{
        #####Get Default parameters ########
        $connected = $response = $null
        if($AADPortal){
            $portal_url = "https://aad.portal.azure.com/api/DelegationToken?feature.tokencaching=true"
        }
        else{
            $portal_url = "https://portal.azure.com/api/DelegationToken?feature.tokencaching=true"
        }
        #Check verbose options
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $VerboseOptions=@{Verbose=$true}
        }
        else{
            $VerboseOptions=@{Verbose=$false}
        }
        #Check Debug options
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $VerboseOptions.Add("Debug",$true)
        }
        else{
            $VerboseOptions.Add("Debug",$false)
        }
        #Check informationAction
        if($PSBoundParameters.ContainsKey('InformationAction') -and $PSBoundParameters.InformationAction){
            $VerboseOptions.Add("InformationAction",$PSBoundParameters.InformationAction)
        }
        else{
            $VerboseOptions.Add("InformationAction","SilentlyContinue")
        }
        #Get token from Azure
        $param = @{
            credential = $PSBoundParameters.credential;
            TenantId = $PSBoundParameters.TenantId;
            AADPortal = $AADPortal.IsPresent;
            InformationAction = $VerboseOptions.InformationAction;
            Verbose = $VerboseOptions.Verbose;
            Debug = $VerboseOptions.Debug;
        }
        $azure_token = Connect-AzurePortal @param
        if($null -ne $azure_token -and $azure_token -ne $azure_token.psobject.properties.Item('oAuthToken')){
            $connected = $true
            #Write message
            $msg = @{
                MessageData = ($Script:messages.SuccessfullyConnectedTo -f "Azure Portal")
                InformationAction = $VerboseOptions.InformationAction;
            }
            Write-Information @msg
        }
    }
    Process{
        if($connected){
            if(-NOT $TenantId){
                $TenantId = $tenantId = $azure_token.user.tenantId
            }
            $SessionID = (New-Guid).ToString().Replace("-","")
            $cookie = ("browserId={0};portalId={0}" -f $Script:client_request_id, $Script:client_request_id)
            #Set headers
            $Headers=@{
                "x-ms-client-request-id" = (New-Guid).ToString()
                "x-ms-extension-flags" ='{"feature.browsecuration":"aad","feature.internalonly":"false","feature.npspercent":"5.0","feature.settingsportalinstance":"aad","feature.skipfavoritesupgrade":"true","feature.usesimpleavatarmenu":"true","hubsextension_hideassettypes":"ARGSharedQueries","feature.acceptallsvgcolors":"true","feature.argbatchcases":"true","feature.argresourcebrowse":"true","feature.argschemaapi":"true","feature.argschemasearch":"true","feature.argtagsfilter":"true","feature.artbrowse":"true","feature.autoargresourcebrowse":"true","feature.autosettings":"true","feature.cloudsimplereservations":"true","feature.dashboardfilters":"true","feature.dashboardfiltersaddbutton":"true","feature.dashboardpreviewapi":"false","feature.deploy2019":"true","feature.dialogtags":"true","feature.disablebladecustomization":"true","feature.disabledextensionredirects":"","feature.doclink":"true","feature.enablee2emonitoring":"true","feature.enableaeoemails":"false","feature.enableconfigurealerts":"true","feature.experimentation":"true","feature.failajaxonnulltoken":"true","feature.feedback":"true","feature.feedbackwithsupport":"true","feature.fullwidth":"true","feature.fxregionsegments":"true","feature.hidemodalsonsmallscreens":"true","feature.invalidatesimplerefreshtokens":"true","feature.irismessagelimit":"5","feature.isworkbooksavailable":"true","feature.managevminbrowse":"true","feature.mistendpoint":"https://mist.monitor.azure.com","feature.mspexpert":"true","feature.mspfilter":"true","feature.mspinfo":"true","feature.newautoscale":"true","feature.newresourceapi":"true","feature.newsupportblade":"true","feature.noonscreenlauncherparts":"true","feature.nps":"true","feature.outagebanner":"true","feature.prefetchdrafttoken":"true","feature.providers2019":"true","feature.refreshtokenbinding":"true","feature.reservationsinbrowse":"true","feature.reservehozscroll":"true","feature.resizeobserver":"true","feature.resourcehealth":"true","feature.resourcetagsapi":"true","feature.seetemplate":"true","feature.serveravatar":"true","feature.setsamesitecookieattribute":"true","feature.showdecoupleinfobox":"true","feature.tenantscoperedirect":"true","feature.tilegallerycuration":"false","feature.tokencaching":"true","feature.usealertsv2blade":"true","feature.usemdmforsql":"true","feature.virtualdropdown":"false","feature.vtext":"true","feature.zerosubsexperience":"true","hubsextension_argtags":"true","hubsextension_azureexpert":"true","hubsextension_budgets":"true","hubsextension_costalerts":"true","hubsextension_costanalysis":"true","hubsextension_costrecommendations":"true","hubsextension_eventgrid":"true","hubsextension_exporttemplateparams":"true","hubsextension_isinsightsextensionavailable":"true","hubsextension_islogsbladeavailable":"true","hubsextension_isomsextensionavailable":"true","hubsextension_nosubsdescriptionkey":"default","hubsextension_regionsegments":"true","hubsextension_savetotemplatehub":"true","microsoft_azure_marketplace_itemhidekey":"Citrix_XenDesktop_EssentialsHidden,Citrix_XenApp_EssentialsHidden,AzureProject"}'
                "x-ms-version" = "5.0.303.1151 (production#59e67b9c58.200114-0738) Signed"
                "X-Requested-With" = "XMLHttpRequest"
                "x-ms-client-session-id" = $SessionID
                "Origin" = "https://portal.azure.com/"
                "x-ms-effective-locale"="en.en-us"
                "Accept-Language" = "en"
                "Cookie" = $cookie
            }
            #Set body
            $Body=@{
                "extensionName" = $extension_type;
                "portalAuthorization" = $azure_token.refreshToken;
                "resourceName" = $token_type
                "tenant" = $TenantId
            }
            #convert body to JSON
            $body = $body | ConvertTo-Json
            #Get response
            $param = @{
                Url = $portal_url;
                Headers = $Headers;
                Method = "Post";
                Content_Type = 'application/json';
                Encoding = "application/json, text/javascript, */*; q=0.01";
                Data= $body;
                Referer = "https://portal.azure.com/";
                InformationAction = $VerboseOptions.InformationAction;
                Verbose = $VerboseOptions.Verbose;
                Debug = $VerboseOptions.Debug;
            }
            $response = New-WebRequest @param
        }        
    }
    End{
        try{
            if($response){
                Write-Information ("New token received")
                $access_Token = $response.value.authHeader.Split(" ")[1]
                $refresh_Token = $azure_token.refreshToken
                $alt_refresh_Token = $azure_token.altRefreshToken
                $user = $azure_token.user
                $new_token_dict = [ordered]@{
                    access_token = $access_Token;
                    refresh_token = $refresh_Token;
                    alt_refresh_token = $alt_refresh_Token;
                    user = $user
                }
                $token_object = New-Object PSObject -Property $new_token_dict
                $parsed_token = Read-JWTtoken -token $token_object.access_token
                Write-Verbose ("Token has the following scopes: {0}" -f $parsed_token.scp)
                return $token_object
            }
        }
        catch{
            Write-Warning ("Unable to create delegated token object")
            Write-Verbose ("The error was: {0} -f" -f $_)
            return $null
        }
    }
}