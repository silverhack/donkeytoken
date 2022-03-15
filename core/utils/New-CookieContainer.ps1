Function New-CookieContainer{
    try{
        #create cookiejar and set script variable
        $cookiejar = New-Object System.Net.CookieContainer 
        Set-Variable cookiejar -Value $cookiejar -Scope Script -Force
    }
    catch{
        Write-Information "Unable to set new cookie container"
    }
}