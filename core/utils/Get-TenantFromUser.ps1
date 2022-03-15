Function Get-TenantFromUser{
    [cmdletbinding()]
    Param(
        [parameter(Mandatory=$true)]
        [string]$userName
    )
    Begin{
        $user_metadata = $domain_metadata = $az_domain_metadata = $null
        $URI_Username = ("https://login.microsoftonline.com/getuserrealm.srf?login={0}&json=1" -f $userName)
    }
    Process{
        if($null -ne $URI_Username){
            $param = @{
                Url = $URI_Username;
                Method = "Get";
                Content_Type = "application/json";
            }
            $user_metadata = New-WebRequest @param
            if ($null -ne $user_metadata -and $user_metadata.PSObject.Properties.Item('DomainName')){
                $URI_tmp_domain = ("https://login.windows.net/{0}/.well-known/openid-configuration" -f $user_metadata.DomainName)
                $param = @{
                    Url = $URI_tmp_domain;
                    Method = "Get";
                    Content_Type = "application/json";
                }
                $domain_metadata = New-WebRequest @param
            }
            #Generate object
            if($domain_metadata -AND $user_metadata){
                $az_domain_metadata = @{
                    domainName = $user_metadata.DomainName;
                    NameSpaceType = $user_metadata.NameSpaceType;
                    FederationBrandName = $user_metadata.FederationBrandName;
                    CloudInstanceName = $user_metadata.CloudInstanceName;
                    TenantID = $domain_metadata.token_endpoint.Split(‘/’)[3]
                }
            }
        }
    }
    End{
        if($az_domain_metadata){
            #return object
            [pscustomobject]$az_domain_metadata
        }
        else{
            Write-Warning -Message ("Unable to resolve TenantID")
        }
    }
}