Function Get-FormattedMessage {
    [CmdletBinding()]
    Param (
        [System.Management.Automation.InformationRecord] $Log
    )
    Begin{
        $formattedMessage = $null
        #Check Log Level
        if($null -eq $Log.Level -or [String]::IsNullOrEmpty($Log.Level)){
            $Log.Level = 'info'
        }
        else{
            $Log.Level = $Log.Level.ToString().ToLower();
        }
    }
    Process{
        if($Log.MessageData -is [System.Management.Automation.ErrorRecord]){
            $formattedMessage = (
                "[{0}] - [{1}] - {2}. LineNumber: {3} - exception - {4} - {5}" -f `
                $Log.TimeGenerated.ToUniversalTime().ToString('HH:mm:ss:fff'), `
                $Log.Source, `
                $Log.MessageData.Exception.Message, `
                $Log.MessageData.InvocationInfo.PositionMessage, `
                $Log.Computer, `
                [system.String]::Join(", ", $Log.Tags)
            )
        }
        elseif($Log.MessageData -is [exception]){
            $formattedMessage = (
                "[{0}] - [{1}] - {2}. LineNumber: {3} - exception - {4} - {5}" -f `
                $Log.TimeGenerated.ToUniversalTime().ToString('HH:mm:ss:fff'), `
                $Log.Source, `
                $Log.MessageData, `
                $Log.MessageData.InvocationInfo.PositionMessage, `
                $Log.Computer, `
                [system.String]::Join(", ", $Log.Tags)
            )
        }
        elseif($Log.MessageData -is [System.AggregateException]){
            $formattedMessage = (
                "[{0}] - [{1}] - {2} - {3} - {4} - {5}" -f `
                $Log.TimeGenerated.ToUniversalTime().ToString('HH:mm:ss:fff'), `
                $Log.Source, `
                $Log.MessageData.Exception.InnerException.Message, `
                $Log.Level.ToString().ToLower(), `
                $Log.Computer, `
                [system.String]::Join(", ", $Log.Tags)
            )
        }
        elseif($Log.MessageData -is [String]){
            $formattedMessage = 
                '[{0}] - [{1}] - {2} - {3} - {4} - {5}' -f `
                $Log.TimeGenerated.ToUniversalTime().ToString('HH:mm:ss:fff'), `
                $Log.Source, `
                $Log.MessageData, `
                $Log.Level.ToString().ToLower(), `
                $Log.Computer, `
                [system.String]::Join(", ", $Log.Tags)
        }
        else{
            $formattedMessage = 
                '[{0}] - [{1}] - {2} - {3} - {4} - {5}' -f `
                $Log.TimeGenerated.ToUniversalTime().ToString('HH:mm:ss:fff'), `
                $Log.Source, `
                ($Log.MessageData | Out-String), `
                $Log.Level.ToString().ToLower(), `
                $Log.Computer, `
                [system.String]::Join(", ", $Log.Tags)
            
        }
    }
    End{
        if($formattedMessage){
            return $formattedMessage
        }
        else{
            return $null
        }
    }
}