$PSOSDTModule = @'

function helloOSD {
  "Hello from PSOSDTModule!"
}

function Get-OSDTSEnvironment {
  $Script:TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
}

function Get-OSDVariable {
  param (
    [Parameter(Mandatory = $True)]$Name
  )
  if ( ! $TSEnv ) { Get-OSDTSEnvironment }
  $TSEnv.value("$Name")
}

function Set-OSDVariable {
  param (
    [Parameter(Mandatory = $True)]$Name ,
    [Parameter(Mandatory = $True)]$Value
  )
  if ( ! $TSEnv ) { Get-OSDTSEnvironment }
  $TSEnv.value("$Name") = "$Value"
}

'@

$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$TSEnv.value('PSOSDTModule') = $PSOSDTModule
