$PSOSDTModule = @'

<#
 Usefull default Task Sequence Variables
 REF: https://learn.microsoft.com/en-us/mem/configmgr/osd/understand/task-sequence-variables
 _SMSTSInWinPE
_SMSTSLaunchMode
_SMSTSLogPath
_SMSTSMachineName
_SMSTSMake
_SMSTSMDataPath
_SMSTSMediaType
  BootMedia: Boot Media
  FullMedia: Full Media
  PXE: PXE
  OEMMedia: Prestaged Media
_SMSTSModel
_SMSTSMP
#>

function Test-PSOSDT {
  "Hello from PSOSDT Module !"
}

function ConvertFrom-OSDBase64String {
  param (
    [string[]]$EncodedString
  )
  $FName = $MyInvocation.MyCommand.Name

  $EncodedString | ForEach-Object { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) }
}

function ConvertTo-OSDBase64String {
  param (
    [string[]]$String
  )
  $String | ForEach-Object {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($_)
    [Convert]::ToBase64String($bytes)
  }
}

function Get-OSDTSEnvironment {
  $Script:TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
  $FName = $MyInvocation.MyCommand.Name
}

function Get-OSDVariable {
  [CmdletBinding()]
  param (
    $Name,
    [switch]$OutputToPSVarOnly ,
    [string]$PSVarOutputDescription = 'PSOSDT' ,
    [switch]$ValueOnly ,
    [array]$SkipVars = (
      'AuthToken',
      'certificate',
      'certs',
      'clientconfig',
      'crypto',
      'PSModule',
      'PSOSDTModule',
      'password',
      'MediaPFX',
      'policy',
      'PowerShellScriptSourceScript',
      'reserved',
      'RootKey',
      'SvcPW',
      'tasksequence',
      'UATTesters',
      '_SMSTSAuthenticator',
      '_SMSTSClientSelfProveToken',
      '_SMSTSDPAuthToken',
      '_SMSTSHTTP',
      '_SMSTSMediaApp',
      '_SMSTSPackageCacheLocation',
      '_SMSTSPKGFLAGS',
      '_SMSTSPkgHash',
      '_SMSTSPolicy',
      '_SMSTSSourceVersion',
      '_SMSTSTaskSequence',
      '_SMSTSRoot',
      '_TSSub',
      'sms',
      'LEAVE HERE TO PREVENT ACCIDENTAL LAST ENTRY WITH A COMMA'
    )
  )
  $FName = $MyInvocation.MyCommand.Name

  if (! $TSEnv) {
    Get-OSDTSEnvironment 
  }

  # Filter out unwanted TSVariables
  $TSVars = $TSenv.GetVariables()
  foreach ($TSVar in $TSVars) {
    $Output = $true
    foreach ($SkipVar in $SkipVars) {
      if ($TSVar -like "*$SkipVar*") {
        $Output = $false
      }
    }
    if ($Output) {
      [array]$TSVarsFiltered += $TSVar
    }
  }
  $TSVars = $TSVarsFiltered

  # Get TSVariables to Powershell Variables
  foreach ($TSVar in $TSVars) {
    $Value = $TSEnv.value("$TSVar")
    New-Variable -Name $TSVar -Value $Value -Scope Global -Description $PSVarOutputDescription -ErrorAction SilentlyContinue -Force
  }

  $Params = @{ ErrorAction = 'SilentlyContinue' }
  if ($Name) { $Params += @{ Name = $Name } }

  $filter = {
  ($_.Description -eq $PSVarOutputDescription)
  }

  $Command = 'Get-Variable @Params | Where-Object -FilterScript $filter' 
  if ($ValueOnly) {
    $Command = "($Command).Value"
  }

  if (!$OutputToPSVarOnly) {
    Invoke-Expression -Command $Command
  }
}

function Set-OSDVariable {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)]$Name ,
    [Parameter(Mandatory = $True)]$Value
  )
  $FName = $MyInvocation.MyCommand.Name
  if (! $TSEnv) {
    Get-OSDTSEnvironment 
  }
  $TSEnv.value("$Name") = "$Value"
  New-Variable -Name $Name -Value $Value -Description 'PSOSDT' -Scope Global -Force
}

function Get-OSDComputerSystem {
  $FName = $MyInvocation.MyCommand.Name
  "$FName`: Creating computer system properties as standard variables"
  (Get-CimInstance -ClassName Win32_ComputerSystem).PSObject.Members | ForEach-Object { 
    New-Variable -Name $_.Name -Value $_.value -Scope Global
  }
}

function Test-OSDHPBIOSWMIInterface {
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
  while ((!($HP_BIOSSettingInterface = Get-WmiObject @GWMIParms -ErrorAction SilentlyContinue)) -and $int -lt $MaxWaitSeconds) { 
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

function Show-OSDPopup {
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

    [ValidateSet("Button1", "Button2", "Button3")]
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
  if (Get-OSDVariable -Name '_SMSTSInWinPE') {
    "$FName`: Is running in WinPE. Closing Task Sequence Progress Window if running."
        (New-Object -ComObject Microsoft.SMS.TsProgressUI).CloseProgressDialog() | Out-Null
  }
  "$FName`: Popup:$title;$message;$buttons"
  "$FName`: Display form and get user selection" | Write-Verbose
  [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
  $Result = [Windows.Forms.MessageBox]::Show($message, $title, [Windows.Forms.MessageBoxButtons]::$buttons , [Windows.Forms.MessageBoxIcon]::$type , [Windows.Forms.MessageBoxDefaultButton]::$DefaultButton)

  # Reboot or shutdown if needed or just return user result
  switch ($Result) {
    { 
            ($Result -eq 'Abort' -and $RestartOnAbort) -or
            ($Result -eq 'Cancel' -and $RestartOnCancel) -or
            ($Result -eq 'No' -and $RestartOnNo) -or
            ($Result -eq 'Ok' -and $RestartOnOk)
    } { 
      "$FName`: Restarting Computer"
      Restart-Computer -Force
      Start-Sleep -Seconds 60
    }
    { 
            ($Result -eq 'Abort' -and $ShutdownOnAbort) -or
            ($Result -eq 'Cancel' -and $ShutdownOnCancel) -or
            ($Result -eq 'No' -and $ShutdownOnNo) -or
            ($Result -eq 'Ok' -and $ShutdownOnOk)
    } {
      "$FName`: Shutting down computer"
      Stop-Computer -Force
      Start-Sleep -Seconds 60
    }
    Default {
      RETURN $Result 
    }
  }
}

function Test-OSDMinRAMGB {
  [CmdletBinding()]
  param (
    [int]$MinRAMGB
  )
  $FName = $MyInvocation.MyCommand.Name
  (Get-CimInstance -ClassName CIM_PhysicalMemory).Capacity / 1GB -ge $MinRAMGB
}

function Test-OSDMinCPUGHz {
  [CmdletBinding()]
  param (
    [int]$MinCPUGHz = 4
  )
  $FName = $MyInvocation.MyCommand.Name
  $CPUMax = (Get-CimInstance -ClassName CIM_Processor).MaxClockSpeed | Sort-Object -Descending | Select-Object -First 1
  [math]::Floor($CPUMax / 1024) -ge $MinCPUGHz
}

function Test-OSDMinDiskGB {
  [CmdletBinding()]
  param (
    [int]$MinDiskGB = 128
  )
  $FName = $MyInvocation.MyCommand.Name
  [bool]$(Get-PhysicalDisk | Where-Object { 
      $_.Size -ge "$($MinDiskGB)GB" -and 
      $_.SpindleSpeed -eq 0 -and 
      $_.BusType -notin "USB", 7 
    }
  )
}

function Test-OSDOnBattery {
  [CmdletBinding()]
  param ()
  $FName = $MyInvocation.MyCommand.Name
  ((Get-WmiObject WIN32_Battery) -and (Get-WmiObject WIN32_Battery).BatteryStatus -ne '2')
}

function Get-OSDOSDisk {
  [CmdletBinding()]
  param (
    [ValidateSet('NVMe', 'SCSI', 'RAID', 'MMC')]
    [String]$BusTypeP1 = 'NVMe',
    [ValidateSet('NVMe', 'SCSI', 'RAID', 'MMC')]
    [String]$BusTypeP2 ,
    [ValidateSet('NVMe', 'SCSI', 'RAID', 'MMC')]
    [String]$BusTypeP3 ,
    $MinDiskSizeGB = 64 ,
    [switch]$DeviceIDOnly,
    [switch]$GetLargestSize
  )
  
  $PhysicalDisk = Get-PhysicalDisk 

  # Set sorting order of the disk capacity
  if ($GetLargestSize) {
    $Params = @{ Descending = $True } 
  }
  else { 
    $Params = @{ Descending = $false } 
  }

  # Add BusTypes in order or priority. Works even if one value is null
  foreach ($BusType in $BusTypeP1, $BusTypeP2, $BusTypeP3) {
    $OSDisk = $PhysicalDisk | Where-Object { $_.BusType -eq $BusType -and $_.Size -ge "$($MinDiskSizeGB)GB" } | Sort-Object @Params -Property Size |  Select-Object -First 1 
    if ($OSDisk) {
      break 
    } 
  }

  if ($DeviceIDOnly) {
    $OSDisk.DeviceId
  }
  else {
    $OSDisk
  }
}

function Test-OSDBootMediaImage {
  [CmdletBinding()]
  param ()
  $FName = $MyInvocation.MyCommand.Name
  $_SMSTSBootImageID = Get-OSDVariable -Name '_SMSTSBootImageID'
  $_SMSTSBootMediaPackageID = Get-OSDVariable -Name '_SMSTSBootMediaPackageID'
  "$FName`: Task Sequnece BootImageID: $_SMSTSBootImageID , Boot Media BootImageID: $_SMSTSBootMediaPackageID" | Write-Verbose
  $_SMSTSBootImageID -eq $_SMSTSBootMediaPackageID
}

function Get-OSDChassisModelType {
  param (
    [switch]$OutputToPSVarOnly,
    [switch]$TypeOnly,
    [switch]$ModelOnly,
    [switch]$ValueOnly
  )
  $FName = $MyInvocation.MyCommand.Name
    
  "$FName`: Setting default Chassis type values to false" | Write-Verbose
  $Global:isLaptop = $false
  $Global:isDesktop = $false
  $Global:isServer = $false
  $Global:isVM = $false
    
  $ChassisTypes = (Get-CimInstance -ClassName Win32_SystemEnclosure).ChassisTypes
  $ChassisTypes | ForEach-Object {
    switch ($_) {
      { $_ -in '8', '9', '10', '11', '12', '14', '18', '21', '30', '31', '32' } {
        $Global:isLaptop = $true
        $type = 'isLaptop'
        Set-OSDVariable -Name "isLaptop" -Value $true
      }
      { $_ -in '3', '4', '5', '6', '7', '13', '15', '16' } {
        $Global:isDesktop = $true
        $type = 'isDesktop'
        Set-OSDVariable -Name "isDesktop" -Value $true
      }
      { $_ -in '23' } {
        $Global:isServer = $true
        $type = 'isServer'
        Set-OSDVariable -Name "isServer" -Value $true
      }
      Default { 
        $type = 'isUknown'
        "$FName`: Cannot determine if Laptop, Desktop or Server" | Write-warning 
      }
    }
  }
  $Model = (Get-CimInstance -ClassName Win32_ComputerSystem).Model
  if ($Model -in 'VMware20,1', 'VMware7,1', 'VirtualBox', 'VMware Virtual Platform', 'Virtual Machine', 'Standard PC (Q35 + ICH9, 2009)') {
    $Global:isVM = $true
    Set-OSDVariable -Name "isVM" -Value $true
  }
  if (! $OutputToPSVarOnly) {
    if ($TypeOnly) {
      if ($ValueOnly) {
        Get-Variable -Name type -ValueOnly
      }
      else {
        Get-Variable -Name type
      }
    }
    elseif ($ModelOnly) {
      if ($ValueOnly) {
        Get-Variable -Name Model -ValueOnly
      }
      else {
        Get-Variable -Name Model
      }
    }
    else {
      Get-Variable -Name ChassisTypes, type, isLaptop, isDesktop, isServer, isVM, Model
    }
  }
}

function Test-OSDIsLaptop {
  [CmdletBinding()]
  param ()

  Get-OSDChassisModelType -OutputToPSVarOnly
  $isLaptop
}
function Test-OSDIsDesktop {
  [CmdletBinding()]
  param ()

  Get-OSDChassisModelType -OutputToPSVarOnly
  $isDesktop
}
function Test-OSDIsServer {
  [CmdletBinding()]
  param ()

  Get-OSDChassisModelType -OutputToPSVarOnly
  $isServer
}
function Test-OSDIsVM {
  [CmdletBinding()]
  param ()

  Get-OSDChassisModelType -OutputToPSVarOnly
  $isVM
}
'@


# Output to OSD Variable accessible throughout the whole task sequence
$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$TSEnv.value('PSOSDTModule') = $PSOSDTModule
# Output to X: RAMDrive in WinPE for script development with Import-Module cmdlet
try {
  $PSOSDTModule | Out-File x:\PSOSDT.psm1 -Force ; Import-Module x:\PSOSDT.psm1 -Force 
}
finally {
}
