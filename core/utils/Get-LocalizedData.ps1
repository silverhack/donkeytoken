function Get-LocalizedData{
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1, ParameterSetName = 'TargetedUICulture')]
        [System.String]
        $UICulture,

        [Parameter()]
        [System.String]
        $BaseDirectory,

        [Parameter()]
        [System.String]
        $FileName,

        [Parameter(Position = 1, ParameterSetName = 'DefaultUICulture')]
        [System.String]
        $DefaultUICulture
    )
    Begin{
        if (!$PSBoundParameters.ContainsKey('FileName')){
            if ($myInvocation.ScriptName){
                $file = [System.IO.FileInfo] $myInvocation.ScriptName
            }
            else{
                $file = [System.IO.FileInfo] $myInvocation.MyCommand.Module.Path
            }
            $FileName = $file.BaseName
            #$PSBoundParameters.Add('FileName', $file.Name)
        }
        if ($PSBoundParameters.ContainsKey('BaseDirectory')){
            $callingScriptRoot = $BaseDirectory
        }
        else{
            $callingScriptRoot = $MyInvocation.PSScriptRoot
            $PSBoundParameters.Add('BaseDirectory', $callingScriptRoot)
        }
        if ($PSBoundParameters.ContainsKey('DefaultUICulture') -and !$PSBoundParameters.ContainsKey('UICulture')){
            <#
                We don't want the resolution to eventually return the ModuleManifest
                so we run the same GetFilePath() logic than here:
                https://github.com/PowerShell/PowerShell/blob/master/src/Microsoft.PowerShell.Commands.Utility/commands/utility/Import-LocalizedData.cs#L302-L333
                and if we see it will return the wrong thing, set the UICulture to DefaultUI culture, and return the logic to Import-LocalizedData
            #>
            $currentCulture = Get-UICulture
            $languageFile = $null
            $localizedFileNames = @(
                $FileName + '.psd1'
                $FileName + '.strings.psd1'
            )
            while ($null -ne $currentCulture -and $currentCulture -is [System.Globalization.CultureInfo] -and !$languageFile){
                if($currentCulture.Name.Length -gt 0){
                    $cultureName = $currentCulture.Name
                }
                else{
                    $cultureName = 'en-US'                        
                }
                foreach ($fullFileName in $localizedFileNames){
                    $filePath = [io.Path]::Combine($callingScriptRoot, $cultureName, $fullFileName)
                    if (Test-Path -Path $filePath){
                        Write-Verbose -Message "Found $filePath"
                        $languageFile = $filePath
                        # Set the filename to the file we found.
                        $PSBoundParameters['FileName'] = $fullFileName
                        $PSBoundParameters['BaseDirectory'] = [io.Path]::Combine($callingScriptRoot, $cultureName)
                        # Exit loop if we find the first filename.
                        break
                    }
                    else{
                        Write-Verbose -Message "File $filePath not found"
                        #Write-Host "File $filePath not found"
                    }
                }
                $currentCulture = $currentCulture.Parent
            }
            if (!$languageFile){
                $PSBoundParameters.Add('UICulture', $DefaultUICulture)
            }
            $null = $PSBoundParameters.Remove('DefaultUICulture')
        }
    }
    Process{
        #Import localized Data
        if($PSBoundParameters.ContainsKey('FileName') -and $fullFileName){
            Import-LocalizedData @PSBoundParameters
        }
        else{
            Write-Warning "Unable to get Localized data file"
        }
    }
    End{
        #Nothing to do here
    }
}

