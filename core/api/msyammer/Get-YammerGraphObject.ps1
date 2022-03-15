Function Get-YammerGraphObject{
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectType,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Filter,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Expand,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Top,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$orderBy,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String[]]$Select,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$Count,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$RawQuery,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("CONNECT","GET","POST","HEAD","PUT")]
        [String]$Method = "GET",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ContentType = "application/json",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$Data
    )
    Begin{
        if($null -eq $Authentication){
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Microsoft Yammer Graph API")
             return
        }
        #Get Authorization Header
        $AuthHeader = ("Bearer {0}" -f $Authentication.access_token)
        #set msgraph uri
        $base_uri = ("https://msgraph.yammer.com/v1.0/me")
        $my_filter = $null
        #construct query
        if($Expand){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$expand={1}' -f $my_filter, $Expand)
            }
            else{
                $my_filter = ('?$expand={0}' -f $Expand)
            }
        }
        if($Filter){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$filter={1}' -f $my_filter, [uri]::EscapeDataString($Filter))
            }
            else{
                $my_filter = ('?$filter={0}' -f [uri]::EscapeDataString($Filter))
            }
        }
        if($Select){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$select={1}' -f $my_filter, (@($Select) -join ','))
            }
            else{
                $my_filter = ('?$select={0}' -f (@($Select) -join ','))
            }
        }
        if($orderBy){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$orderby={1}' -f $my_filter, $orderBy)
            }
            else{
                $my_filter = ('?$orderby={0}' -f $orderBy)
            }
        }
        if($Top){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$top={1}' -f $my_filter, $Top)
            }
            else{
                $my_filter = ('?$top={0}' -f $Top)
            }
        }
        if($Count){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$count=true' -f $my_filter)
            }
            else{
                $my_filter = ('?$count=true' -f $Top)
            }
        }
        if($ObjectType){
            $base_uri = ("{0}/{1}" -f $base_uri, $ObjectType)
        }
        if($ObjectId){
            $base_uri = ("{0}/{1}" -f $base_uri, $ObjectId)
        }
        #construct final URI
        if($my_filter){
            $final_uri = ("{0}{1}" -f $base_uri,$my_filter)
        }
        else{
            $final_uri = $base_uri
        }
        if($RawQuery){
            if($my_filter){
                $final_uri = ("{0}/{1}{2}" -f $base_uri,$RawQuery,$my_filter)
            }
            else{
                $final_uri = ("{0}/{1}" -f $base_uri,$RawQuery)
            }
        }
    }
    Process{
        if($final_uri){$requestHeader = @{"x-ms-version" = "2014-10-01";"Authorization" = $AuthHeader}}
        #Perform query
        $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($final_uri)
        $ServicePoint.ConnectionLimit = 1000;
        try{
            $AllObjects = @()
            switch ($Method) { 
                    'GET'
                    {
                        $param = @{
                            Url = $final_uri;
                            Headers = $requestHeader;
                            Method = $Method;
                            Content_Type = "application/json";
                        }
                        $Objects = New-WebRequest @param
                    }
                    'POST'
                    {
                        if($Data){
                            $param = @{
                                Url = $final_uri;
                                Headers = $requestHeader;
                                Method = $Method;
                                Content_Type = $ContentType;
                                Data = $Data;
                            }
                        }
                        else{
                            $param = @{
                                Url = $final_uri;
                                Headers = $requestHeader;
                                Method = $Method;
                                Content_Type = $ContentType;
                            }
                        }
                        #Execute Query request
                        $Objects = New-WebRequest @param
                    }
            }
            if($ObjectType){
                Write-Verbose ("Trying to get {0} from microsoft graph" -f $ObjectType)
            }
            else{
                Write-Verbose $final_uri
            }
            if($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -gt 0){
                $AllObjects+= $Objects.value
            }
            elseif($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -eq 0){
                #empty response
                return $Objects.value
            }
            else{
                $AllObjects+= $Objects
            }
            #Search for paging objects
            if ($Objects.'@odata.nextLink'){
                $nextLink = $Objects.'@odata.nextLink'
                while ($null -ne $nextLink){
                    ####Workaround for operation timed out ######
                    #https://social.technet.microsoft.com/wiki/contents/articles/29863.powershell-rest-api-invoke-restmethod-gotcha.aspx
                    $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($nextLink)
                    #Make RestAPI call
                    $param = @{
                        Url = $nextLink;
                        Method = "Get";
                        Headers = $requestHeader;
                    }
                    $NextPage = New-WebRequest @param
                    $AllObjects+= $NextPage.value
                    $nextLink = $nextPage.'@odata.nextLink'
                }
            }
            ####close all the connections made to the host####
            [void]$ServicePoint.CloseConnectionGroup("")
        }
        catch{
            Write-Verbose $_
            ####close all the connections made to the host####
            [void]$ServicePoint.CloseConnectionGroup("")
            return $null
        }
    }
    End{
        if($AllObjects){
            return $AllObjects
        }
    }
}