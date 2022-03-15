Function ConvertTo-XML{
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$RawObject
    )
    try{
        $StrWriter = New-Object System.IO.StringWriter
        $DataDoc = New-Object system.xml.xmlDataDocument
        $DataDoc.LoadXml($RawObject)
        $Writer = New-Object system.xml.xmltextwriter($StrWriter)
        #Indented Format
        $Writer.Formatting = [System.xml.formatting]::Indented
        $DataDoc.WriteContentTo($Writer)
        #Flush Data
        $Writer.Flush()
        $StrWriter.flush()
        #Return data
        return $StrWriter.ToString()
    }
    catch{
        Write-Debug -Message "Unable to convert data to XML"
        return $null
    }
}