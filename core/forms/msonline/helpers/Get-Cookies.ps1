# Return cookies from cookie container
function Get-Cookies{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false)]
        [String]$Domain,

        [Parameter(Mandatory=$False)]
        [Switch]$all

    )
    try{
        if($null -ne (Get-Variable -Name cookiejar -ErrorAction Ignore)){
            if($PSBoundParameters.ContainsKey('Domain') -and $PSBoundParameters.Domain){
                return $cookiejar.GetCookieHeader("{0}" -f $Domain)
            }
            elseif($PSBoundParameters.ContainsKey('all') -and $PSBoundParameters.all.IsPresent){
                #https://hochwald.net/get-cookies-from-powershell-webrequestsession/
                [pscustomobject]$CookieInfoObject = (($cookiejar).GetType().InvokeMember('m_domainTable',
                                                                                         [Reflection.BindingFlags]::NonPublic -bor [Reflection.BindingFlags]::GetField -bor [Reflection.BindingFlags]::Instance,
                                                                                         $null, $cookiejar, @()))
                return ((($CookieInfoObject).Values).Values)

            }
        }
    }
    catch{
        Write-Warning "Unable to get cookie from cookie container"
        Write-Verbose $_
    }
}