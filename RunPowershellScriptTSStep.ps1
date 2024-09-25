"Importing Powershell OS Deployment Toolkit Module."
$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$PSOSDTModule = $TSEnv.value('PSOSDTModule')
Invoke-Expression -Command $PSOSDTModule

#MAIN

helloOSD
Get-OSDVariable -Name 'OSDComputerName'
Get-OSDVariable -Name '_SMSTSPackageName'
Set-OSDVariable -Name 'MyVar' -Value 'MyValue'
Get-OSDVariable -Name 'MyVar'
Get-OSDComputerSystem
$Manufacturer
$Model
if ( $Manufacturer -in 'hp','hewlett packard' ) { Test-HPBIOSWMIInterface }

# Wait awhile to open CMTrace and view results
Start-Sleep -Seconds 30000
