"Importing Powershell OS Deployment Toolkit Module."
$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
$PSOSDTModule = $TSEnv.value('PSOSDTModule')
Invoke-Expression -Command $PSOSDTModule

#MAIN

Get-OSDVariable -Name 'OSDComputerName'
Get-OSDVariable -Name '_SMSTSPackageName'
Set-OSDVariable -Name 'MyVar' -Value 'MyValue'
Get-OSDVariable -Name 'MyVar'
Get-OSDComputerSystem
$Manufacturer
$Model

Show-OSDPopup -title "Message Title" -message "Message body text" -type Exclamation -buttons AbortRetryIgnore -DefaultButton Button2 -ShutdownOnAbort

Get-OSDVariable -Name '_SMSTSModel'
if ( $Manufacturer -in 'hp','hewlett packard' ) { Test-HPBIOSWMIInterface }

# Wait awhile to open CMTrace and view results
Start-Sleep -Seconds 30000
