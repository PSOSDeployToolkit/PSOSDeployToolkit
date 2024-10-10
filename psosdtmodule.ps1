$PSOSDTModule = @'

function Test-PSOSDT
{
  "Hello from PSOSDT Module !"
}

function Get-OSDTSEnvironment
{
  $Script:TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
  $FName = $MyInvocation.MyCommand.Name
}

function Get-OSDVariable
{
  param (
    $Name,
    [switch]$OutputToPSVarOnly ,
    [array]$SkipVars = ("AuthToken", "certificate", "certs", "clientconfig", 
      "crypto", "PSModule", "password", "MediaPFX", "policy", 
      "PowerShellScriptSourceScript", "reserved", "RootKey", 
      "_SMSTSAuthenticator", "_SMSTSClientSelfProveToken", "_SMSTSDPAuthToken", 
      "_SMSTSHTTP", "_SMSTSMediaApp", "_SMSTSPackageCacheLocation", 
      "_SMSTSPKGFLAGS", "_SMSTSPkgHash", "_SMSTSPolicy", "_SMSTSSourceVersion", 
      "_SMSTSTaskSequence", "_SMSTSRoot", "SvcPW", "_TSSub", "tasksequence", 
      "UATTesters" )
  )
  $FName = $MyInvocation.MyCommand.Name

  if ( ! $TSEnv )
  { Get-OSDTSEnvironment 
  }

  if ( ! $Name)
  {
    $Name = $TSenv.GetVariables() 
  }

  foreach ($var in $Name)
  {
    $output = $true
    foreach ($skipVar in $skipVars)
    {
      if ( $var -like "*$skipVar*" )
      { 
        $output = $false
      }
    }
      if ( $output ) {
        $Value = $TSEnv.value("$var")
          New-Variable -Name $var -Value $Value -Scope Global -Description 'PSOSDT' -ErrorAction SilentlyContinue -Force
        if (! $OutputToPSVarOnly) {
          Get-Variable -Name $var -ValueOnly
        }
      }
  }
}

function Set-OSDVariable
{
  param (
    [Parameter(Mandatory = $True)]$Name ,
    [Parameter(Mandatory = $True)]$Value
  )
  $FName = $MyInvocation.MyCommand.Name
  if ( ! $TSEnv )
  {
    Get-OSDTSEnvironment 
  }
  $TSEnv.value("$Name") = "$Value"
  New-Variable -Name $Name -Value $Value -Scope Global
}

function Get-OSDComputerSystem
{
  $FName = $MyInvocation.MyCommand.Name
  "$FName`: Creating computer system properties as standard variables"
  (Get-CimInstance -ClassName Win32_ComputerSystem).PSObject.Members | ForEach-Object { 
    New-Variable -Name $_.Name -Value $_.value -Scope Global
  }
}

function Test-HPBIOSWMIInterface
{
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
  while ((!($HP_BIOSSettingInterface = Get-WmiObject @GWMIParms -ErrorAction SilentlyContinue)) -and $int -lt $MaxWaitSeconds )
  { 
    "$FName`: Waiting up to $MaxWaitSeconds seconds for HP BIOS WMI interface: $int" 
    Start-Sleep -Seconds 1
    $int += 1
  }
  if ($int -ge $MaxWaitSeconds)
  {
    "$FName`: HP BIOS WMI Interface did not load in $MaxWaitSeconds"
    RETURN $false
  } ELSE
  {
    Return $true
  }
}

function Show-OSDPopup
{
  [CmdletBinding()]
  Param (
    [ValidateNotNullOrEmpty()]
    [String] 
    $Title = 'Operating System Deployment Condition Check',

    [ValidateNotNullOrEmpty()]
    [string]
    $Message = 'Click [Ok] to continue OR [Cancel] to quit.',

    [ValidateSet("Asterisk", "Error", "Exclamation", "Hand", "Information", "None", "Question", "Stop", "Warning")]
    [String]
    $Type = "Information",

    [ValidateSet("AbortRetryIgnore", "OK", "OKCancel", "RetryCancel", "YesNo", "YesNoCancel")]
    $Buttons = "OKCancel",

    [ValidateSet("Button1","Button2","Button3")]
    $DefaultButton = "Button1",
        
    [switch] $ShutdownOnAbort,
    [switch] $RestartOnAbort,

    [switch] $ShutdownOnNo,
    [switch] $RestartOnNo,

    [switch] $ShutdownOnCancel,
    [switch] $RestartOnCancel,

    [switch] $ShutdownOnOk,
    [switch] $RestartOnOk
  )
  $FName = $MyInvocation.MyCommand.Name
  "$FName`: Testing if in WindowsPE. If so, hide the OSD Progress window."
  if ( Get-OSDVariable -Name '_SMSTSInWinPE' )
  {
    "$FName`: Is running in WinPE. Closing Task Sequence Progress Window if running."
        (New-Object -ComObject Microsoft.SMS.TsProgressUI).CloseProgressDialog() | Out-Null
  }
  "$FName`: Popup:$title;$message;$buttons"
  "$FName`: Display form and get user selection" | Write-Verbose
  [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
  $Result = [Windows.Forms.MessageBox]::Show($message, $title, [Windows.Forms.MessageBoxButtons]::$buttons ,[Windows.Forms.MessageBoxIcon]::$type ,[Windows.Forms.MessageBoxDefaultButton]::$DefaultButton )

  # Reboot or shutdown if needed or just return user result
  switch ($Result)
  {
    { 
            ($Result -eq 'Abort' -and $RestartOnAbort) -or
            ($Result -eq 'Cancel' -and $RestartOnCancel) -or
            ($Result -eq 'No' -and $RestartOnNo) -or
            ($Result -eq 'Ok' -and $RestartOnOk)
    }
    { 
      "$FName`: Restarting Computer"
      Restart-Computer -Force
      Start-Sleep -Seconds 60
    }
    { 
            ($Result -eq 'Abort' -and $ShutdownOnAbort) -or
            ($Result -eq 'Cancel' -and $ShutdownOnCancel) -or
            ($Result -eq 'No' -and $ShutdownOnNo) -or
            ($Result -eq 'Ok' -and $ShutdownOnOk)
    }
    {
      "$FName`: Shutting down computer"
      Stop-Computer -Force
      Start-Sleep -Seconds 60
    }
    Default
    { RETURN $Result 
    }
  }
}

function Test-OSDMinRAMGB
{
  param (
    [int]$MinRAMGB
  )
  $FName = $MyInvocation.MyCommand.Name
  (Get-CimInstance -ClassName CIM_PhysicalMemory).Capacity / 1GB -ge $MinRAMGB
}

function Test-OSDMinCPUGHz
{
  param (
    [int]$MinCPUGHz = 4
  )
  $FName = $MyInvocation.MyCommand.Name
  $CPUMax = (Get-CimInstance -ClassName CIM_Processor).MaxClockSpeed | Sort-Object -Descending | Select-Object -First 1
  [math]::Floor($CPUMax / 1024) -ge $MinCPUGHz
}

function Test-OSDMinDiskGB
{
  param (
    [int]$MinDiskGB = 128
  )
  $FName = $MyInvocation.MyCommand.Name
  [bool]$(Get-PhysicalDisk | Where-Object { 
      $_.Size -ge "$($MinDiskGB)GB" -and 
      $_.SpindleSpeed -eq 0 -and 
      $_.BusType -notin "USB",7 
    })
}

'@


# Output to OSD Variable accessible throughout the whole task sequence
$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$TSEnv.value('PSOSDTModule') = $PSOSDTModule
# Output to X: RAMDrive in WinPE for script development with Import-Module cmdlet
try { $PSOSDTModule | Out-File x:\PSOSDT.psm1 -Force } finally {}