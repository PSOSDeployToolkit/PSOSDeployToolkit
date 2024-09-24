$PSOSDTModule = @'
function helloOSD {
  "Hello from PSOSDTModule!"
}
'@

$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$TSEnv.value('PSOSDTModule') = $PSOSDTModule
