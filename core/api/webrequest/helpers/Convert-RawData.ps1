Function Convert-RawData{
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$RawObject,

        [parameter(Mandatory=$False, HelpMessage='Content type')]
        [String]$ContentType
    )
    switch -Regex ($ContentType) { 
        "application/(json)"
        {
            $RawResponse = ConvertFrom-Json -InputObject $RawObject
        }
        "application/(xml)"
        {
            $RawResponse = ConvertTo-XML -RawObject $RawObject
        }
        Default
        {
            $RawResponse = $RawObject
        }
    }
    #Return Object
    Return $RawResponse
}