# STATUS: WORK IN PROGRESS
Very alpha

# PSOSDeployToolkit
PowerShell Operating System Deployment Toolkit (PSOSDT)

Collection of PowerShell functions for Microsoft Configuration Manager based Windows Operating System deployment Task Sequences.

### Disclaimer
Neither this project or I am in any way affiliated with Microsoft.

### Resources:
- [Task sequence variables](https://learn.microsoft.com/en-us/mem/configmgr/osd/understand/task-sequence-variables)

## Instructions

### Enable Powershell support in your OS Deployment boot image if needed.
> [!WARNING]
> Following these steps will require redistribution of your OS Deployment boot image to distribution points and recreation of all associated physical OS Deployment boot media.
> Do not perform these steps on a boot image that is being used in production environments without coordinating all required efforts to recreate all exiting physical boot media.
> You have been warned.

1. Open Configuration Manager Console:
1. Navigate to Software Distribution > Operating Systems > Boot Images.
1. Right-click the your boot image and choose Properties.
1. Switch to the "Optional Components" tab.
1. Click on Add and select "Windows PowerShell (WinPE-Powershell)" from the list of available components.
> [!NOTE]
> When you select this option you may be prompted to add prerequisite components. Confirm the prompt to add them if presented.
1. Click OK to close the properties window.
1. You may want to right-click the boot image again and select Update Distribution Points to ensure that all changes are applied.

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
