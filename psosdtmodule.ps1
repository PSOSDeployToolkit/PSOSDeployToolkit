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

function Test-HPBIOSWMIInterface {
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

function Show-OSDPopup {
    [CmdletBinding()]
    Param (
        [ValidateNotNullOrEmpty()]
        [String] 
        $title = 'Operating System Deployment Condition Check',

        [ValidateNotNullOrEmpty()]
        [string]
        $message = 'Click [Ok] to continue OR [Cancel] to quit.',

        [ValidateSet("Asterisk", "Error", "Exclamation", "Hand", "Information", "None", "Question", "Stop", "Warning")]
        [String]
        $type = "Information",

        [ValidateSet("AbortRetryIgnore", "OK", "OKCancel", "RetryCancel", "YesNo", "YesNoCancel")]
        $buttons = "OKCancel",

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
    if ( Get-OSDVariable -Name '_SMSTSInWinPE' ) {
        "$FName`: Is running in WinPE. Closing Task Sequence Progress Window if running."
        (New-Object -ComObject Microsoft.SMS.TsProgressUI).CloseProgressDialog() | Out-Null
    }
    "$FName`: Popup:$title;$message;$buttons"
    "$FName`: Display form and get user selection" | Write-Verbose
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
    $Result = [Windows.Forms.MessageBox]::Show($message, $title, [Windows.Forms.MessageBoxButtons]::$buttons ,[Windows.Forms.MessageBoxIcon]::$type ,[Windows.Forms.MessageBoxDefaultButton]::$DefaultButton )

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
        Default { RETURN $Result }
    }
}

function Test-OSDMinRAM {
    param (
        [int]$MinRAMinGB
    )
    (Get-CimInstance -ClassName CIM_PhysicalMemory).Capacity / 1GB -ge $MinRAMinGB
}

function Test-OSDMinCPUinGHz {
    param (
        [int]$MinCPUGhz = 4
    )
    $CPUMax = (Get-CimInstance -ClassName CIM_Processor).MaxClockSpeed | Sort-Object -Descending | Select-Object -First 1
    [math]::Floor($CPUMax / 1024) -ge $MinCPUGhz
}

function Test-OSDMinDiskinGB {
    param (
        [int]$MinDiskinGB = 128
    )
    [bool]$(Get-PhysicalDisk | Where-Object { 
        $_.Size -ge "$($MinDiskinGB)GB" -and 
        $_.SpindleSpeed -eq 0 -and 
        $_.BusType -notin "USB",7 
    })
}

'@


# Output to OSD Variable accessible throughout the whole task sequence
$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$TSEnv.value('PSOSDTModule') = $PSOSDTModule
# Output to X: RAMDrive in WinPE for script development with Import-Module cmdlet
$PSOSDTModule | Out-File x:\PSOSDT.psm1