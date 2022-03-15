Function ConvertTo-O365AccessToken{
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$token,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [string]$username
    )
    try{
        $access_Token = $token.TokenValue
        $token_expires = $token.ExpiryMs
        $resourceId = $token.ResourceId
        #create PsObject
        $new_token = New-Object -TypeName PSCustomObject
        $new_token | Add-Member -type NoteProperty -name access_token -value $access_Token
        $new_token | Add-Member -type NoteProperty -name expires -value $token_expires
        $new_token | Add-Member -type NoteProperty -name resource -value $resourceId
        $new_token | Add-Member -type NoteProperty -name user -value $username
        #return token object
        return $new_token
    }
    catch{
        Write-Warning ("Unable to create token object")
        Write-Warning ("The error was: {0} -f" -f $_)
        return
    }
}