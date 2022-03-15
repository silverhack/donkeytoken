Function Get-RSTFaultDetails{
    [CmdletBinding()]
    Param(
        [parameter(Mandatory= $true, HelpMessage= "fault message")]
        [xml]$raw_message
    )
    Begin{
        #Add namespace
        $namespace_manager = New-Object System.Xml.XmlNamespaceManager($raw_message.NameTable)
        $namespaceUri = $raw_message.DocumentElement.NamespaceURI
        $namespace_manager.AddNamespace("wsse", $namespaceUri)
        $namespace_manager.AddNamespace("S", $namespaceUri)
        $namespace_manager.AddNamespace("wsa", $namespaceUri)
        $namespace_manager.AddNamespace("wsp", $namespaceUri)
        $namespace_manager.AddNamespace("wsu", $namespaceUri)
        $namespace_manager.AddNamespace("wst", $namespaceUri)
        $namespace_manager.AddNamespace("ps", $namespaceUri)
        #Get header
        $header = $raw_message.SelectSingleNode("//S:Envelope/S:Header", $namespace_manager)
        #Get body
        $body = $raw_message.SelectSingleNode("//S:Envelope/S:Body", $namespace_manager)
        #Error codes
        #https://docs.microsoft.com/en-us/previous-versions/office/developer/lync-online/hh472110(v=office.14)
        $error_codes = @{
            "0x48044" = "PPCRL_S_ALREADY_INITIALIZED"
            "0x80048008" = "PP_E_CRL_NOT_INITIALIZED"
            "0x80048821" = "PPCRL_REQUEST_E_BAD_MEMBER_NAME_OR_PASSWORD"
            "0x80048801" = "PPCRL_AUTHSTATE_E_EXPIRED"
            "0x80048810" = "PPCRL_AUTHREQUIRED_E_PASSWORD"
            "0x80048814" = "PPCRL_AUTHREQUIRED_E_UNKNOWN"
            "0x80048820" = "PPCRL_REQUEST_E_AUTH_SERVER_ERROR"
            "0x80048823" = "PPCRL_REQUEST_E_PASSWORD_LOCKED_OUT"
            "0x80048824" = "PPCRL_REQUEST_E_PASSWORD_LOCKED_OUT_BAD_PASSWORD_OR_HIP"
            "0x80048825" = "PPCRL_REQUEST_E_TOU_CONSENT_REQUIRED"
            "0x80048826" = "PPCRL_REQUEST_E_FORCE_RENAME_REQUIRED"
            "0x80048827" = "PPCRL_REQUEST_E_FORCE_CHANGE_PASSWORD_REQUIRED"
            "0x8004882A" = "PPCRL_REQUEST_E_PARTNER_NOT_FOUND"
            "0x80048800" = "PPCRL_AUTHSTATE_E_UNAUTHENTICATED"
        }
        $error_code = $error_codes.Item($header.pp.authstate)
        if($null -eq $error_code){
            $error_code = $header.pp.authstate
        }
        $body_text = $body.Fault.Detail.error.internalerror.text
    }
    Process{
        $error_message = ("{0}: {1}" -f $error_code, $body_text)
    }
    End{
        return $error_message
    }
}