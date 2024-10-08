# STATUS: WORK IN PROGRESS
Very alpha

# PSOSDeployToolkit
PowerShell Operating System Deployment Toolkit (PSOSDT)

Collection of PowerShell functions for Microsoft Configuration Manager based Windows Operating System deployment Task Sequences.

### Disclaimer
Neither this project or I am in any way affiliated with Microsoft.

### Resources:
- [Task sequence variables](https://learn.microsoft.com/en-us/mem/configmgr/osd/understand/task-sequence-variables)

### Prerequisites
- PowerShell support enabled boot image

## Instructions

### If Needed: Add Powershell Optional Components to your OS Deployment boot image.
> [!WARNING]
> These steps require redistribution of your OS Deployment boot image and recreation of all associated physical OS Deployment boot media.
> Do not perform these steps on production boot images without coordinating efforts required to recreate all exiting physical boot media.
> You have been warned.

1. Open Configuration Manager Console:
1. Navigate to Software Distribution > Operating Systems > Boot Images.
1. Right-click the your boot image and choose Properties.
1. Switch to the "Optional Components" tab.
1. Click on the Add (star icon) and select "Windows PowerShell (WinPE-Powershell)".
> [!NOTE]
> You may be prompted to install additional prerequisites. Click Yes if prompted.
1. Click OK to close the properties window.
1. Click Yes when prompted to redistribute your boot image.
> [!NOTE]
> Do not check the option "Reload this boot image with the current Windows PE version from the Windows ADK" if your current boot image was generated with the MDT Boot Image Wizard. It will remove all customizations provided by MDT.

### Enable PSOSDT in your Task Sequence.
1. Open existing Operating System Deployment Task sequence.
1. Create new Task Sequence step "Run PowerShell Script" at the top of the sequence and set the following options:
    - "PowerShell execution policy": bypass
    - "Enter a PowerShell script": Selected
        - "Edit Script...": click/copy/paste contents of "psosdtmodule.ps1" from repo.

### Using PSOSDT functions in your Enabled Task Sequence
1. Open existing and PSOSDT Enabled Operating System Deployment Task sequence.
1. Create new Task Sequence step "Run PowerShell Script" at the desired location in the sequence and set the following options:
    - "PowerShell execution policy": bypass
    - "Enter a PowerShell script": Selected
        - Edit Script...: click/copy/paste contents of "RunPowershellScriptTSStep.ps1" from repo and edit as desired.
