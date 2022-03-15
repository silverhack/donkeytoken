Function Get-ConfigFromUrl{
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$inputObject
    )
    try{
        $configPattern = [Regex]::new('{.*}')
        $matches = $configPattern.Matches($inputObject)
        $parsed_config = $matches[0].Value | ConvertFrom-Json
        return $parsed_config
    }
    catch{
        Write-Warning ("Unable to get config")
        Write-Warning ("The error was: {0} -f" -f $_)
        return $null
    }
}