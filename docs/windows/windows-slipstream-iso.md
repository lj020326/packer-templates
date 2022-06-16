
# Windows Slipstream

## Creating updated ISO from an existing ISO

This repository contains an example of using Packer to create a Windows ISO image with slipstreamed updates.

The idea is to use Packer and Vagrant to slipstream updates into an existing ISO. This is done by creating a VirtualBox OS from the ISO, updating it, and then slipstreaming the updates into a new ISO.

## Why vagrant is used

Vagrant is used as it allows the loading and updating of the latest / previous ISO. This means that the updates can be applied from the updated Windows OS (i.e. ```C:\Windows\SoftwareDistribution\Download\```) and a new ISO created with them. Making the update process very meta.

# Setup

## Download Windows ISO

Download the latest ISO (e.g. 'Windows 2016') into folder ```packer/templates/windows/packer_cache```.

e.g.

```bash
packer/templates/windows/packer_cache/en_windows_server_2016_vl_x64_dvd_11636701.iso
```

## Download any extra updates

Download any extra MSU and CAB files to folder ```packer/templates/windows/packer_cache/Updates/Windows2016_64```.

## Create ADK offline installer

Creating an offline installer for "Windows Assessment and Deployment Kit" (ADK) can speed-up build times.

### Build via packer

```bash
cd packer/templates/windows/
```

*e.g.*

```bash
packer build --on-error=ask -var headless=false -var "iso_url=packer_cache/en_windows_server_2016_vl_x64_dvd_11636701.iso" -var "iso_checksum=e3779d4b1574bf711b063fe457b3ba63" -var "guest_os_type=Windows2016_64" -var "autounattend=../../files/answer_files/server_2016/without_updates/Autounattend.xml" create_adk_offline_installer.json
```

> Change variables as needed!

### Alternatively, build using Powershell on Windows without Packer

*e.g.*

```powershell
$env:INSTALLER_TYPE="EXE"
$env:INSTALL_FROM="URL"
$env:INSTALLER_DISPLAYNAME="Windows Assessment and Deployment Kit - Windows 10"
$env:INSTALL_EXE_ARGUMENTS="/quiet /layout C:\Windows\Temp\ADKoffline"
$env:INSTALLER_URI="https://go.microsoft.com/fwlink/?linkid=2026036"
$env:INSTALLER_NAME="adksetup.exe"
$env:FORCE_INSTALL="true"
$env:POST_INSTALL="compress"
$env:POST_INSTALL_COMPRESS_PATH="C:\Windows\Temp\ADKoffline"
$env:POST_INSTALL_COMPRESS_OUTPUT_PATH="C:\Windows\Temp\ADKoffline.zip"

packer/provisioners/powershell/install-from.ps1
```

## Get Oracle Installer Cert

This cert can be exported from a Windows machine where "Oracle VM VirtualBox Guest Additions" was previously installed and placed in folder ```packer/files/certs```.

## Generate MD5 from ISO for ```iso_checksum```

#### Bash

```bash
md5 packer/templates/windows/packer_cache/en_windows_server_2016_vl_x64_dvd_11636701.iso
```

#### Powershell

```powershell
Get-FileHash .\packer\templates\windows\packer_cache\SW_DVD9_Win_Svr_STD_Core_and_DataCtr_Core_2016_64Bit_English_-3_MLF_X21-30350.ISO -Algorithm MD5
```

## Windows - Powershell

Ensure that ```packer``` and ```VBoxManage``` are in the environment variables ```$env:Path```.

e.g.

```powershell
$env:Path = "C:\Program Files\Oracle\VirtualBox"
```

# Variables

## Environment Variables for ```slipstream-iso.ps1```

|Environment Variables|Description|Default|
|---|---|---|
|```IMAGE_NAME```|This is a regular expression that is used to select the images inside the WIM.|```.*```|
|```INSTALL_LIST_FILE```|Applies updates in the order they are listed within this file.|```_Updates.txt```|
|```APPLY_INSTALLED_UPDATES```|Apply MSU and CAB files that are found on the guest OS in path ```C:\Windows\SoftwareDistribution\Download\``` ||
|```UPDATES_FOLDER```|Path to installer folder.||
|```ISO_OUTPUT_PATH```|ISO output filename.|```\\\\VBOXSVR\\vagrant\\WindowsServer2016_Patched_{{isotime \"2006-01-02\"}}.iso```|

### Example of ```INSTALL_LIST_FILE```

Each uncommented line of the ```INSTALL_LIST_FILE``` is used to search for file paths containing the line text. Only the first matching update is applied.

An example of this file is as follows: -

```
# Windows2016_64

# Updates will be applied in the following order.
KB4465659
KB4091664
KB4480977
```

> If this file does not exist in the root of the ```UPDATES_FOLDER``` all MSU and CAB files in the folder tree will be applied.

## Packer ```windows_slipstream.json``` template variables

|Template Variables|Description|Default|
|---|---|---|
|```iso_url```|Path to a Windows ISO||
|```iso_checksum```|Windows ISO MD5 checksum||
|```guest_os_type```|VirtualBox Guest OS Type||
|```updates_folder```|Path to folder containing MSU and CAB installer files|```\\\\VBOXSVR\\vagrant\\Updates\\Windows2016_64```|
|```autounattend```|Path to Autounattend XML file|```{{template_dir}}/../../files/answer_files/server_2016/with_updates/Autounattend.xml```|
|```adk_installer_uri```|URI to ADK installer|```https://go.microsoft.com/fwlink/?linkid=2026036```|

### List VirtualBox Windows Guest Types for ```guest_os_type```

```bash
VBoxManage list ostypes | grep -e '^ID' | sed -E -e "s/^ID:[[:blank:]]+//g" | grep -e 'Windows'
```

# Using ADK offline installer

1. Create ```packer_cache``` offline folder ```packer/templates/windows/packer_cache/Offline```.

2. Create ADK offline installer, [Create ADK offline installer](#create-adk-offline-installer), and move output file ```ADKoffline.zip``` to ```packer_cache``` offline folder.

3. Use offline installer: -  

    ```bash
    cd packer/templates/windows/
    ```

    **Validate**

    *e.g.*

    ```bash
    packer validate -var headless=false -var 'iso_url=packer_cache/WindowsServer2016_Patched.iso' -var 'iso_checksum=932d3d7f14a3a938bb8ff73f486d64b9' -var 'guest_os_type=Windows2016_64' -var 'autounattend=../../files/answer_files/server_2016/without_updates/Autounattend.xml' -var "adk_installer_uri=file://\\\\VBOXSVR\\vagrant\\Offline\ADKoffline.zip" windows_slipstream.json
    ```

    **Build**

    *e.g.*

    ```bash
    time PACKER_LOG=1 PACKER_LOG_PATH="windows_slipstream.log" packer build --on-error=ask -var headless=false -var 'iso_url=packer_cache/WindowsServer2016_Patched.iso' -var 'iso_checksum=932d3d7f14a3a938bb8ff73f486d64b9' -var 'guest_os_type=Windows2016_64' -var 'autounattend=../../files/answer_files/server_2016/without_updates/Autounattend.xml' windows_slipstream.json
    ```

- Change variables as needed!
- The above examples uses an ```Autounattend.xml``` file which doesn't install updates.

# Run

```bash
cd packer/templates/windows/
```

**Validate**

*e.g.*

```bash
packer validate -var headless=false -var 'iso_url=packer_cache/en_windows_server_2016_vl_x64_dvd_11636701.iso' -var 'iso_checksum=e3779d4b1574bf711b063fe457b3ba63' -var 'guest_os_type=Windows2016_64' windows_slipstream.json
```

**Validate - Powershell**

*e.g.*

```bash
packer validate -var headless=false -var "iso_url=packer_cache\SW_DVD9_Win_Svr_STD_Core_and_DataCtr_Core_2016_64Bit_English_-3_MLF_X21-30350.ISO" -var "iso_checksum=EEB465C08CF7243DBAAA3BE98F5F9E40" -var "guest_os_type=Windows2016_64" windows_slipstream.json
```

**Build 'ask on error'**

*e.g.*

```bash
packer build --on-error=ask -var headless=false -var 'iso_url=packer_cache/en_windows_server_2016_vl_x64_dvd_11636701.iso' -var 'iso_checksum=e3779d4b1574bf711b063fe457b3ba63' -var 'guest_os_type=Windows2016_64' windows_slipstream.json
```

**Build 'ask on error' - Powershell**

*e.g.*

```powershell
packer build --on-error=ask -var headless=false -var "iso_url=packer_cache\SW_DVD9_Win_Svr_STD_Core_and_DataCtr_Core_2016_64Bit_English_-3_MLF_X21-30350.ISO" -var "iso_checksum=EEB465C08CF7243DBAAA3BE98F5F9E40" -var "guest_os_type=Windows2016_64" windows_slipstream.json
```

**Build 'ask on error' (timed)**

*e.g.*

```bash
time PACKER_LOG=1 PACKER_LOG_PATH="windows_slipstream.log" packer build --on-error=ask -var headless=false -var 'iso_url=packer_cache/en_windows_server_2016_vl_x64_dvd_11636701.iso' -var 'iso_checksum=e3779d4b1574bf711b063fe457b3ba63' -var 'guest_os_type=Windows2016_64' windows_slipstream.json
```

**Build 'ask on error' (not timed) - Powershell**

*e.g.*

```powershell
$env:PACKER_LOG=1
$env:PACKER_LOG_PATH="windows_slipstream.log"

packer build -var headless=false -var "iso_url=packer_cache\SW_DVD9_Win_Svr_STD_Core_and_DataCtr_Core_2016_64Bit_English_-3_MLF_X21-30350.ISO" -var "iso_checksum=EEB465C08CF7243DBAAA3BE98F5F9E40" -var "guest_os_type=Windows2016_64" windows_slipstream.json
```

**Build 'ask on error', logging and timed, without updates**

By defining ```autounattend``` as ```./../files/answer_files/server_2016/without_updates/Autounattend.xml```.

*e.g.*

```bash
time PACKER_LOG=1 PACKER_LOG_PATH="windows_slipstream.log" packer build --on-error=ask -var headless=false -var 'iso_url=packer_cache/WindowsServer2016_Patched.iso' -var 'iso_checksum=932d3d7f14a3a938bb8ff73f486d64b9' -var 'guest_os_type=Windows2016_64' -var 'autounattend=../../files/answer_files/server_2016/without_updates/Autounattend.xml' --force windows_slipstream.json
```

**Build 'ask on error' and logging, without updates - Powershell**

*e.g.*

```powershell
$env:PACKER_LOG=1
$env:PACKER_LOG_PATH="windows_slipstream.log"

packer build --on-error=ask -var headless=false -var "iso_url=packer_cache\SW_DVD9_Win_Svr_STD_Core_and_DataCtr_Core_2016_64Bit_English_-3_MLF_X21-30350.ISO" -var "iso_checksum=EEB465C08CF7243DBAAA3BE98F5F9E40" -var "guest_os_type=Windows2016_64" -var "autounattend=../../files/answer_files/server_2016/without_updates/Autounattend.xml" windows_slipstream.json
```

## Reference

* https://github.com/jpnewman/Windows-Slipstream
* 
