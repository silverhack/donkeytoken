Function Write-Warning {
    [CmdletBinding(HelpUri='https://go.microsoft.com/fwlink/?LinkId=525909', RemotingCapability='None')]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [Alias('Msg')]
        [Alias('MessageData')]
        [System.Object]
        ${Message},

        [Parameter(Position=1)]
        [string[]]
        ${Tags},

        [Parameter(Mandatory=$false, Position=2, HelpMessage="Foreground Color")]
        [ConsoleColor]$ForegroundColor = $Host.UI.RawUI.ForegroundColor,

        [Parameter(Mandatory=$false, Position=3, HelpMessage="Background Color")]
        [ConsoleColor]$BackgroundColor = $Host.UI.RawUI.BackgroundColor,

        [Parameter(Mandatory=$false, HelpMessage="CallStack")]
        [System.Management.Automation.CallStackFrame]
        $callStack,

        [Parameter(Mandatory=$false, HelpMessage="Function name")]
        [String]$functionName,

        [Parameter(Mandatory=$false, HelpMessage="Log Level")]
        [String]$logLevel,

        [Parameter(Mandatory=$false, HelpMessage="channel output")]
        [String[]]$channel,

        [Parameter(Mandatory=$false, HelpMessage="Function name")]
        [object]$Caller,

        [Parameter(Mandatory=$false, Position=5, HelpMessage="No new line")]
        [Switch]$NoNewline)

    begin
    {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            try{
                $TmpCommand = (Get-PSCallStack | Select-Object -Skip 1 | Select-Object -First 1).Command
            }
            catch{
                $TmpCommand = $null
            }
            if($null -ne $callStack -and $callStack.Command.Length -gt 0){
                $Command = $callStack.Command;
            }
            elseif($null -ne $callStack -and $callStack.FunctionName.Length -gt 0){
                $Command = $callStack.FunctionName;
            }
            elseif($functionName){
                $Command = $functionName
            }
            elseif($TmpCommand){
                $Command = $TmpCommand
            }
            else{
                $Command = 'UnkNown';
            }
            if($PSBoundParameters.ContainsKey('WarningAction') -and [System.String]::IsNullOrEmpty($PSBoundParameters.WarningAction)){
                $informationAction = $WarningPreference
            }
            elseif($PSBoundParameters.ContainsKey('WarningAction')){
                $informationAction = $PSBoundParameters.WarningAction                
            }
            else{
                $informationAction = $WarningPreference
            }
            #Check Log Level
            if($PSBoundParameters.ContainsKey('logLevel') -and ($null -eq $PSBoundParameters.logLevel -or [String]::IsNullOrEmpty($PSBoundParameters.logLevel))){
                $PSBoundParameters.logLevel = 'warning'
            }
            elseif(!$PSBoundParameters.ContainsKey('logLevel')){
                $PSBoundParameters.logLevel = 'warning'
            }
            #Create msg object
            $msg = [System.Management.Automation.InformationRecord]::new($Message,$Command)
            $msg | Add-Member -type NoteProperty -name InformationAction -value $informationAction
            $msg | Add-Member -type NoteProperty -name ForegroundColor -value $PSBoundParameters['ForegroundColor']
            $msg | Add-Member -type NoteProperty -name BackgroundColor -value $PSBoundParameters['BackgroundColor']
            $msg | Add-Member -type NoteProperty -name Verbose -value $PSBoundParameters['Verbose']
            $msg | Add-Member -type NoteProperty -name level -value $PSBoundParameters['logLevel']
            #Add tags
            if($Tags){
                foreach ($tag in $Tags){$msg.tags.Add($tag)}
            }
            #Get formatted message
            $formattedMessage = Get-FormattedMessage -Log $msg
            if($formattedMessage){
                $formattedMessage = ("WARNING: {0}" -f $formattedMessage)
            }
            #Set color
            if (-NOT $PSBoundParameters.ContainsKey('ForegroundColor')){
                $ForegroundColor = [ConsoleColor]::Yellow
            }
            #Set message options
            $msgObject = [System.Management.Automation.HostInformationMessage]@{
                Message         = $formattedMessage
                ForegroundColor = $ForegroundColor
                BackgroundColor = $BackgroundColor
                NoNewline       = $NoNewline.IsPresent
            }
            #Set write-information options
            $out_message = @{
                MessageData = $msgObject
                tag = $Tags
                InformationAction = $informationAction
            }
            #Execute write-information
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Information', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @out_message }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }
    process
    {
        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }
    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
    <#

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Information
    .ForwardHelpCategory Cmdlet

    #>
}

