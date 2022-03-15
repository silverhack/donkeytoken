Function New-PKCEFlow{
    Begin{
        $code_verifier = $null;
        $code_challengue= $null;
        $replace = @{
            "\+" = "-";
            "/" = "_"
        }
        try{
            $RandomNumberGenerator = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
            $Bytes = New-Object Byte[] 32
            $RandomNumberGenerator.GetBytes($Bytes)
            $code_verifier = ([Convert]::ToBase64String($Bytes)).Substring(0, 43) #([System.Web.HttpServerUtility]::UrlTokenEncode($Bytes)).Substring(0, 43)
            foreach($rp in $replace.GetEnumerator()){
                $code_verifier = $code_verifier -replace $rp.Key,$rp.Value
            }
        }
        catch{
            Write-Error $_
        }
    }
    Process{
        try{
            if($null -ne $code_verifier){
                #Create challenge
                $new_bytes = [System.Security.Cryptography.HashAlgorithm]::Create('SHA256').ComputeHash([System.Text.Encoding]::UTF8.GetBytes($code_verifier))
                $encoded_bytes = [Convert]::ToBase64String($new_bytes) #[System.Web.HttpServerUtility]::UrlTokenEncode($new_bytes)
                $code_challengue = $encoded_bytes.Substring(0,$encoded_bytes.Length-1)
                foreach($rp in $replace.GetEnumerator()){
                    $code_challengue = $code_challengue -replace $rp.Key,$rp.Value
                }
            }
        }
        catch{
            Write-Error $_
        }
    }
    End{
        if($null -ne $code_verifier -and $null -ne $code_challengue){
            $PKCE = @{
                code_challengue = $code_challengue;
                code_verifier = $code_verifier;
            }
            return $PKCE
        }
        else{
            return $null;
        }
    }
}