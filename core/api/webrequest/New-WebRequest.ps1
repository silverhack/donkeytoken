Function New-WebRequest{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$true, position=0,ParameterSetName='Url')]
        [String]$url,

        [parameter(Mandatory=$False, HelpMessage='Request method')]
        [ValidateSet("Connect","Get","Post","Head","Put")]
        [String]$Method = "Get",

        [parameter(Mandatory=$False, HelpMessage='Encoding')]
        [String]$Encoding,

        [parameter(Mandatory=$False, HelpMessage='content type')]
        [String]$Content_Type,

        [parameter(Mandatory=$False, HelpMessage='referer')]
        [String]$Referer,

        [parameter(Mandatory=$False, HelpMessage='timeout')]
        [Int]$TimeOut = 10000,

        [parameter(Mandatory=$False, HelpMessage='cookies')]
        [Object[]]$Cookies,

        [parameter(Mandatory=$False, HelpMessage='Cookie container')]
        [Object]$CookieContainer,

        [parameter(Mandatory=$False, HelpMessage='user agent')]
        [String]$UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:72.0) Gecko/20100101 Firefox/72.0",

        [parameter(Mandatory=$False, HelpMessage='Headers as hashtable')]
        [System.Collections.Hashtable]$Headers,

        [parameter(Mandatory=$False, HelpMessage='POST PUT data')]
        [String]$Data,

        [parameter(Mandatory=$False, HelpMessage='Allows autoredirect')]
        [switch]$AllowAutoRedirect,

        [parameter(Mandatory=$False, HelpMessage='return RAW response')]
        [switch]$returnRawResponse,

        [parameter(Mandatory=$False, HelpMessage='Show response headers')]
        [switch]$showResponseHeaders
        )
    Begin{
        $response = $null
        #Method
        switch ($Method.ToLower()) { 
            'connect'
            {
                $Method = [System.Net.WebRequestMethods+Http]::Connect
            }
            'get'
            {
                $Method = [System.Net.WebRequestMethods+Http]::Get
            }
            'post'
            {
                $Method = [System.Net.WebRequestMethods+Http]::Post
            }
            'put'
            {
                $Method = [System.Net.WebRequestMethods+Http]::Put
            }
            'head'
            {
                $Method = [System.Net.WebRequestMethods+Http]::Head
            }
        }
    }
    Process{
        #Create Request
        try{
            $request = [System.Net.WebRequest]::Create($Url)
        }
        catch{
            #Get exceptions
            Get-WebRequestException -Exception $_ -Url $Url
        }
        if($null -ne $request -and $request -is [System.Net.HttpWebRequest]){
            #Establish Request Method
            $request.Method = $Method
            #Add Expect100
            #Add keepalive
            $request.KeepAlive = $true
            $request.ServicePoint.Expect100Continue = $false;
            $request.ProtocolVersion = [System.Net.HttpVersion]::Version11;
            #Add Headers
            if($Headers){
                foreach($element in $headers.GetEnumerator()){
                    $request.Headers.Add($element.key, $element.value)
                }
            }
            #Control Redirects
            if($PSBoundParameters['AllowAutoRedirect']){
                $request.AllowAutoRedirect = $True
            }
            else{
                $request.AllowAutoRedirect = $false                
            }
            #Add encoding
            if($Encoding){
                #Add Accept
                $request.Accept = $Encoding
            }
            #Add content-type
            if($Content_Type){
                $request.ContentType = $Content_Type
            }
            #Add Cookie container
            if($CookieContainer){
                $request.CookieContainer = $CookieContainer
            }
            #Add Cookies
            if($Cookies){
                foreach($cookie in $Cookies){
                    $request.Headers.add("Cookie", $cookie)
                }
            }
            #Add referer
            if($Referer){
                $request.Referer = $Referer
            }
            #Add custom User-Agent
            $request.UserAgent = $UserAgent
            #Set Timeout to Infinite
            #$request.Timeout = [System.Threading.Timeout]::Infinite
            $request.Timeout = $TimeOut
            #Add cache policy
            $request.CachePolicy = new-object System.Net.Cache.HttpRequestCachePolicy([System.Net.Cache.HttpRequestCacheLevel]::NoCacheNoStore);
            #Create the request body if POST or PUT
            if(($Method -eq [System.Net.WebRequestMethods+Http]::Post -or $Method -eq [System.Net.WebRequestMethods+Http]::Put) -and $Data){
                try{
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Data)
                    $request.ContentLength = $bytes.Length
                    [System.IO.Stream] $outputStream = [System.IO.Stream]$request.GetRequestStream()
                    $outputStream.Write($bytes,0,$bytes.Length)
                    $outputStream.Flush()
                    $outputStream.Close()
                }
                catch{
                    write-Error $_                    
                }
            }
            elseif(($Method -eq [System.Net.WebRequestMethods+Http]::Post -or $Method -eq [System.Net.WebRequestMethods+Http]::Put) -and -NOT $Data){
                $request.ContentLength = 0
            }
            #Lauch Request
            try{
                [System.Net.WebResponse]$response = $request.GetResponse()
                if($showResponseHeaders -and $response -is [System.Net.HttpWebResponse]){
                    Get-WebResponseDetailedMessage -response $response
                }
            }
            ## Catch errors from the server (404, 500, 501, etc.)
            catch [Net.WebException]{
                Get-WebRequestException -Exception $_ -Url $Url
            }
            catch{
                write-Error $_
            }
        }
    }
    End{
        if($returnRawResponse -and $response -is [System.Net.HttpWebResponse]){
            return $response
        }
        elseif($response -is [System.Net.HttpWebResponse]){
            #Get the response stream
            #$rs = $response.GetResponseStream();
            #Get Stream Reader and store into a RAW var
            #[System.IO.StreamReader] $sr = New-Object System.IO.StreamReader -argumentList $rs     
            $sr = [System.IO.StreamReader]::new($response.GetResponseStream())
            #Convert Raw Data
            $stringObject = $sr.ReadToEndAsync().GetAwaiter().GetResult();
            $Rawobject = Convert-RawData -RawObject $stringObject -ContentType $response.ContentType
            #$Rawobject = Convert-RawData -RawObject $sr.ReadToEnd() -ContentType $response.ContentType
            #Close Stream reader
            $sr.Close()
            $sr.Dispose()
            #Close the response stream
            $response.Close()
            #Dispose
            $response.Dispose()
            return $Rawobject
        }
    }
}