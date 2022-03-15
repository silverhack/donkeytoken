Function Get-Functions{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="Array of files")]
        [Object]$Files
    )
    Begin{
        $all_functions = @()
        $tokens = $errors = $null
    }
    Process{
        foreach($fnc in $Files){
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $fnc.FullName,
                [ref]$tokens,
                [ref]$errors
            )
            # Get only function definition ASTs
            $all_functions += $ast.FindAll({
                param([System.Management.Automation.Language.Ast] $Ast)

                $Ast -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                # Class methods have a FunctionDefinitionAst under them as well, but we don't want them.
                ($PSVersionTable.PSVersion.Major -lt 5 -or
                $Ast.Parent -isnot [System.Management.Automation.Language.FunctionMemberAst])

            }, $true)                
        }
    }
    End{
        if($all_functions){
            return $all_functions
        }
        else{
            return $null
        }
    }
}