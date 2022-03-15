Function Get-BasicAuthenticationHeader{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [pscredential]$credential
    )
    Begin{
        $user = $credential.UserName
        $pass = $credential.GetNetworkCredential().password
        $pair = ("{0}:{1}" -f $user,$pass)
    }
    Process{
        $encoded_data = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
        $auth_value = ("Basic {0}" -f $encoded_data)
    }
    End{
        return @{Authorization = $auth_value}
    }
}