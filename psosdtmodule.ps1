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
  $TSEnv.value($Name)
}

'@

$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$TSEnv.value('PSOSDTModule') = $PSOSDTModule
