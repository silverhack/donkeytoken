Function Invoke-MFATest{
    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [pscredential]$credential,

        # Tenant identifier of the authority to issue token.
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [AllowEmptyString()]
        [string] $TenantId,

        [Parameter(HelpMessage="Pause between batchs in milliseconds")]
        [int32]$Sleep = 0,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$direct
    )
    Begin{
        #Set Window name
        $Host.UI.RawUI.WindowTitle = "NCC Group Office 365 Security Scanner"
        #Start Time
        $starttimer = Get-Date
        #####Get Default parameters ########
        $MyParams = $PSBoundParameters
        #Check verbose options
        if($MyParams.ContainsKey('Verbose') -and $MyParams.Verbose){
            $VerboseOptions=@{Verbose=$true}
        }
        else{
            $VerboseOptions=@{Verbose=$false}
        }
        #Check Debug options
        if($MyParams.ContainsKey('Debug') -and $MyParams.Debug){
            $VerboseOptions.Add("Debug",$true)
        }
        else{
            $VerboseOptions.Add("Debug",$false)
        }
        #Check informationAction
        if($MyParams.ContainsKey('InformationAction') -and $MyParams.InformationAction){
            $VerboseOptions.Add("InformationAction",$MyParams.InformationAction)
        }
        else{
            $VerboseOptions.Add("InformationAction","SilentlyContinue")
        }
        
        #Set script path var
        #$ScriptPath = $PWD.Path #Split-Path $MyInvocation.MyCommand.Path -Parent
        $ScriptPath = $PSScriptRoot #Split-Path $MyInvocation.MyCommand.Path -Parent
        Set-Variable -Name ScriptPath -Value $ScriptPath -Scope Script
        #set the default connection limit
        [System.Net.ServicePointManager]::DefaultConnectionLimit = 1000;
        [System.Net.ServicePointManager]::MaxServicePoints = 1000;
        try{
            #https://msdn.microsoft.com/en-us/library/system.net.servicepointmanager.reuseport(v=vs.110).aspx
            [System.Net.ServicePointManager]::ReusePort = $true;
        }
        catch{
            #Nothing to do here
        }
        $PSScriptRoot = Split-Path $PSScriptRoot -Parent
        if($direct.IsPresent){
            $plugins_path = ("{0}/public/formtoken" -f $PSScriptRoot)
            #Getting TenantId or Tenant Name
            if($MyParams.ContainsKey('TenantId') -and $MyParams.TenantId){
                #OK
            }
            else{
                #Get user's tenant
                $Tenant = Get-TenantFromUser -username $credential.UserName
                if($null -ne $Tenant -and $Tenant.psobject.properties.Item('TenantId')){
                    $MyParams.Add('TenantId',$Tenant.TenantId)
                }
                else{
                    #Set user's tenant based on userName
                    try{
                        $Tenant = $credential.UserName.Split('@')[1]
                        $MyParams.Add('TenantId',$Tenant)
                    }
                    catch{
                        $MyParams.Add('TenantId',$null)
                    }
                }
            }
        }
        else{
            if($MyParams.ContainsKey('TenantId') -and $MyParams.TenantId){
                #OK
            }
            else{
                $MyParams.Add('TenantId',$null)                
            }
            $plugins_path = ("{0}/public/formlogin" -f $PSScriptRoot)
        }
        $output_callers = $output_plugins = $null;
        Set-Variable results -Value ([hashtable]::Synchronized(@{})) -Scope Script -Force
    }
    Process{
        #Return if no tenantId is detected when direct connection is selected
        if($direct.IsPresent -and $null -eq $MyParams.TenantId){return}
        $output_callers = Get-ChildItem -Path $plugins_path -Filter '*.ps1'
        if($output_callers){
            $output_plugins = Get-Functions -Files $output_callers
        }
        if($null -ne $output_plugins){
            foreach($_function in $output_plugins){
                $validate_function = $_function.Body.GetScriptBlock()
                $ArgumentList = @{
                    credential=$credential;
                    TenantId = $MyParams.TenantId;
                    InformationAction = $VerboseOptions.InformationAction;
                    Verbose = $VerboseOptions.Verbose;
                    Debug = $VerboseOptions.Debug;
                }
                $param = @{
                    ScriptBlock = {.$validate_function @ArgumentList}
                }
                Invoke-Command @param
                #Check if pause between execution
                if($PSBoundParameters.ContainsKey('Sleep') -and $PSBoundParameters.Sleep -ge 0){
                    Write-Verbose ($script:messages.SleepMessage -f $Sleep)
                    Start-Sleep -Milliseconds $Sleep
                }
            }
        }
    }
    End{
        return $results
    }
}