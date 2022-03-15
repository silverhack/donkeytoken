Function Get-TokenFromOfficePortal{
    <# 
     .SYNOPSIS 
     Acquires OAuth AccessToken from Sharepoint Online 
 
     .DESCRIPTION 
     The Get-TokenFromOfficePortal function lets you acquire a valid OAuth AccessToken from Microsoft 365 portal by passing
     a PSCredential object with a username and password

     .PARAMETER credential
     PSCredential object
 
     .PARAMETER TenantId
     A registerered TenantId.

     .PARAMETER token_type
     valid token within the primaryTokensInfo and secondaryTokensInfo DIV
 
     .EXAMPLE 
     $Credential = Get-Credential -Message "Please, enter user and password:"
     $access_token = Get-TokenFromOfficePortal -credential $Credential -token_type All
 
     This example acquire all access tokens within primaryTokensInfo and secondaryTokensInfo DIV tags by using user&password grant flow.

     .EXAMPLE 
     $Credential = Get-Credential -Message "Please, enter user and password:"
     $access_token = Get-TokenFromOfficePortal -credential $Credential -token_type Graph
 
     This example acquire a valid access token for graph.microsoft.com by using user&password grant flow.
 
    #>
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [pscredential]$credential,

        # Tenant identifier of the authority to issue token.
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [AllowEmptyString()]
        [string] $TenantId,

        [parameter()]
        [ValidateSet("All","Graph","Portal","Exchange", "Loki", "Substrate","Mru","SharePoint","SPS_OneDrive","SharePointSites","QueryFormulation")]
        [String]$token_type = "Graph"
    )
    Begin{
        $Doc = $ps_token = $internal_error = $null
        #Get new parameters
        $new_params = @{}
        foreach ($param in $PSBoundParameters.GetEnumerator()){
            if($param.Key -eq 'token_type'){continue}
            $new_params.add($param.Key, $param.Value)
        }
        $auth_data = Connect-OfficePortal @new_params -GetRawData
        if($null -ne $auth_data){
            #Convert html
            $Doc = New-Object -com "HTMLFILE"
            try{
                $Doc.IHTMLDocument2_write($auth_data)
            }
            catch{
                $src = [System.Text.Encoding]::Unicode.GetBytes($auth_data)
                $Doc.write($src)
            }
        }
    }
    Process{
        if($Doc){
            $primary_tokens = $Doc.getElementsByTagName('div') |  Where-Object { $_.id -eq 'primaryTokensInfo' } | Select-Object -ExpandProperty outerText | ConvertFrom-Json
            $secondary_tokens = $Doc.getElementsByTagName('div') |  Where-Object { $_.id -eq 'secondaryTokensInfo' } | Select-Object -ExpandProperty outerText | ConvertFrom-Json
            $token_names = $primary_tokens.psobject.Properties.name
            $token_names2 = $secondary_tokens.psobject.Properties.name
            $O365_services = $token_names + $token_names2
            #Convert Tokens
            if($token_type -eq "All"){
                foreach($elem in $secondary_tokens.psobject.properties){
                    $primary_tokens | Add-Member -type NoteProperty -name $elem.name -value $elem.value
                }
                $ps_token = @()
                foreach($t in $primary_tokens.psobject.Properties){
                    if(-NOT $t.value.psobject.Properties.Item('HasCAPError')){
                        $tmp_token = ConvertTo-O365AccessToken -token $t.value -username $userName
                        if($tmp_token){
                            $tmp_token.access_token = $t.value.TokenValue
                            $tmp_token.expires = $t.value.ExpiryMs
                            $new_token = New-Object -TypeName PSCustomObject
                            $new_token | Add-Member -type NoteProperty -name $t.name -value $tmp_token
                            $ps_token+=$new_token
                        }
                    }
                }
            }
            elseif($token_type.ToString().Equals("SPS_OneDrive")){
                $tmp_token = $secondary_tokens | Select-Object -ExpandProperty OneDrive -ErrorAction Ignore
                if($null -ne $tmp_token -and -NOT $tmp_token.psobject.Properties.Item('HasCAPError')){
                    $ps_token = ConvertTo-O365AccessToken -token $tmp_token -username $userName
                }
                else{
                    $internal_error = ("[Conditional Access Policy error] Unable to get {0} token object" -f $token_type)
                }
            }
            elseif($primary_tokens.psobject.Properties.Item($token_type)){
                $tmp_token = $primary_tokens | Select-Object -ExpandProperty $token_type -ErrorAction Ignore
                if($null -ne $tmp_token -and -NOT $tmp_token.psobject.Properties.Item('HasCAPError')){
                    $ps_token = ConvertTo-O365AccessToken -token $tmp_token -username $userName
                }
                else{
                    $internal_error = ("[Conditional Access Policy error] Unable to get {0} token object" -f $token_type)
                }
            }
            elseif($secondary_tokens.psobject.Properties.Item($token_type)){
                $tmp_token = $secondary_tokens | Select-Object -ExpandProperty $token_type -ErrorAction Ignore
                if($null -ne $tmp_token -and -NOT $tmp_token.psobject.Properties.Item('HasCAPError')){
                    $ps_token = ConvertTo-O365AccessToken -token $tmp_token -username $userName    
                }
                else{
                    $internal_error = ("[Conditional Access Policy error] Unable to get {0} token object" -f $token_type)
                }
            }
        }
    }
    End{
        if($ps_token){
            return $ps_token
        }
        else{
            Write-Warning ("Unable to get {0} token object" -f $token_type)
            if($internal_error){
                Write-Warning $internal_error
            }
        }
    }
}