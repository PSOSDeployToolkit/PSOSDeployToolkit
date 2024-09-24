$PSOSDTModule = @'

function helloOSD {
  "Hello from PSOSDTModule!"
}

function Get-OSDTSEnvironment {
  $Script:TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
  $FName = $MyInvocation.MyCommand.Name
}

function Get-OSDVariable {
  param (
    [Parameter(Mandatory = $True)]$Name
  )
  $FName = $MyInvocation.MyCommand.Name
  if ( ! $TSEnv ) { Get-OSDTSEnvironment }
  $TSEnv.value("$Name")
}

function Set-OSDVariable {
  param (
    [Parameter(Mandatory = $True)]$Name ,
    [Parameter(Mandatory = $True)]$Value
  )
  $FName = $MyInvocation.MyCommand.Name
  if ( ! $TSEnv ) { Get-OSDTSEnvironment }
  $TSEnv.value("$Name") = "$Value"
}

function Get-OSDComputerSystem {
  $FName = $MyInvocation.MyCommand.Name
  "$FName`: Creating computer system properties as standard variables"
  (Get-CimInstance -ClassName Win32_ComputerSystem).PSObject.Members | ForEach-Object { 
    New-Variable -Name $_.Name -Value $_.value -Scope Script
    }
}

function Test-HPBIOSWMIInterface	{
    [CmdletBinding()]
    Param (
        $MaxWaitSeconds = 180
    ) 
    $FName = $MyInvocation.MyCommand.Name
    $int = 0
    $GWMIParms = @{
        'Namespace' = 'root/HP/InstrumentedBIOS'
        'ClassName' = 'HP_BIOSSettingInterface'
    } 
    while ((!($HP_BIOSSettingInterface = Get-WmiObject @GWMIParms -ErrorAction SilentlyContinue)) -and $int -lt $MaxWaitSeconds ) { 
        "$FName`: Waiting up to $MaxWaitSeconds seconds for HP BIOS WMI interface: $int" 
        Start-Sleep -Seconds 1 
        $int += 1 
    } 
    if ($int -ge $MaxWaitSeconds) { 
        "$FName`: HP BIOS WMI Interface did not load in $MaxWaitSeconds"
        RETURN $false
    }
    ELSE {
        Return $true
    }
}
'@

$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$TSEnv.value('PSOSDTModule') = $PSOSDTModule
