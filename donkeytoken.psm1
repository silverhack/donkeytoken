Set-StrictMode -Version 1.0

Add-Type -AssemblyName System.Web

$DonkeyPrivatePath = ("{0}/core" -f $PSScriptRoot)

$DonkeyFiles = Get-ChildItem -Path $DonkeyPrivatePath -Recurse -File -Include "*.ps1"

foreach($donkeyFile in $DonkeyFiles){
    . $donkeyFile.FullName
}

$fncs = @()

#Load public functions
$Public_fnc = @{
    functions = '/core/forms/functions/'
    public = '/public/'
}

foreach($public_path in $Public_fnc.GetEnumerator()){
    $fncs += Get-ChildItem -Path ("{0}/{1}" -f $PSScriptRoot, $public_path.Value) -Recurse -File -Include "*.ps1"
}

If($fncs){
    foreach($donkeyFile in $fncs){
        . $donkeyFile.FullName
    }
}


$script:messages = Get-LocalizedData -DefaultUICulture 'en-US'