# macOS Virtual Machine for testing using Packer and Tart

This repository contains a Packer configuration (`karthik_macvm-tart.pkr.hcl`) for building a **macOS virtual machine on Apple Silicon** that automatically enrolls into **Jamf Pro** or installs **Microsoft Intune Company Portal*** for testing.  

It’s inspired by [MotionBug’s “The Cookbook: Baking up your perfect Jamf Pro Test VM”](https://www.motionbug.com/the-cookbook-baking-up-your-perfect-jamf-pro-test-vm/) and uses Apple’s **Virtualization framework** with Packer to simulate real-world MDM environments.

---

### What is Packer?

[Packer](https://developer.hashicorp.com/packer) is a tool that lets you create identical machine images for multiple platforms from a single source template. Packer can create golden images to use in image pipelines.

### What is tart?

[Tart](https://tart.run) is a virtualization toolset to build, run and manage macOS and Linux virtual machines on Apple Silicon. Tart uses Apple's own [Virtualization.Framework](https://developer.apple.com/documentation/virtualization) for near-native performance.


## Overview

- Automates macOS Setup Assistant using Tart’s boot commands for a hands‑off build.
- Generates an optional Jamf MDM enrollment profile on the Desktop.
- Toggles for auto‑login, passwordless sudo, Spotlight indexing, Safari automation, and screen lock.
- Installs Tart Guest Agent for clipboard sharing between host and VM.
- Set the Computer Name (VM-TART-XXXX)

## Prerequisites

- Apple Silicon
- [Homebrew](https://brew.sh)
- Packer ≥ 1.7 and Tart ≥ 1.12.0 installed.
- Jamf Pro access to create enrollment invitations.
- Internet connectivity for IPSW and Homebrew installs.
- IPSW Links (https://mrmacintosh.com/apple-silicon-m1-full-macos-restore-ipsw-firmware-files-database/)

## 1. Install tools

```
brew install cirruslabs/cli/tart
brew tap hashicorp/tap
brew install hashicorp/tap/packer
```

## 2. Configuration Variables in packer file

### Core variables
| Name | Type | Default | Description |
|---|---|---|---|
| vm_name | string | sequoia-jamfdev-1542 | Name of the virtual machine to create. |
| ipsw_url | string | https://updates.cdn-apple.com/2025SpringFCS/fullrestores/082-16517/AACDDC33-9683-4431-98AF-F04EF7C15EE3/UniversalMac_15.4_24E248_Restore.ipsw | macOS IPSW restore image URL used to build the VM. |
| account_userName | string | admin | Local macOS account username created during Setup Assistant. |
| account_password | string (sensitive) | CHANGE_ME | Local macOS account password; override via -var or var-file. |
| mdm_vendor | string | jamf | jamf/intune/nomdm |
| jamf_url | string | https://karthik.jamfcloud.com | Jamf Cloud URL |
| mdm_invitation_id | string | 26983012345645772342744680906537738018634 | Jamf Pro enrollment invitation ID used for profile enrollment. |


### Feature toggles
| Name | Type | Default | Description |
|---|---|---|---|
| enable_auto_login | bool | true | Enables automatic login for the specified user. |
| enable_passwordless_sudo | bool | true | Grants passwordless sudo to the specified user via sudoers.d. |
| enable_spotlight_disable | bool | true | Disables Spotlight indexing to reduce background load in lab VMs. |
| enable_safari_automation | bool | true | Launches Safari once and enables safaridriver for automation. |
| enable_screenlock_disable | bool | true | Disables screen lock for the specified user. |
| enable_clipboard_sharing | bool | true | Installs Tart Guest Agent to enable host–guest clipboard sharing. |
| create_mdm_profile | bool | true | Generates an MDM .mobileconfig on Desktop to enroll into Jamf Pro. |

## 3. 🔑Getting Your Jamf Invitation ID (if JAMF is your MDM)

1. Log in to Jamf Pro → **Computers → PreStage Enrollments → Invitations**  
2. Create a new invitation.  
3. Copy the URL that looks like:  
   `https://your.jamfcloud.com/enroll?invitation=XXXXXXXXXXXX`  
4. The part after `invitation=` is your **Invitation ID**.  
5. Add it to `mdm_invitation_id` variable

---

## 4.🧑‍💻Building the VM

```bash
packer init karthik_macvm-tart.pkr.hcl
packer validate karthik_macvm-tart.pkr.hcl
packer build karthik_macvm-tart.pkr.hcl
```
### Override variable at runtime (build)
```packer build -var=“account_userName=macadmin” -var=“account_password=supersecurepass” -var="enable_auto_login=true" karthik_macvm-tart.pkr.hcl```

🟥 $${\color{Red}Note:}$$ No interaction required. Once the image finishes installing, Tart starts the VM and runs the automated setup. Avoid clicking or typing in VM and allow the build to finish.

## 5. Clone your VM with Tart

```
tart clone your-image prod-test-vm
tart set prod-test-vm --display-refit --random-serial --random-mac
tart run my-test-vm
```

### Useful Tart run commands 
```
tart run my-test-vm --dir=SharedFolder:~      # Shared Folders from host to vm
tart run my-test-vm --recovery                # Boot into recovery mode
tart run my-test-vm --no-graphics             # Don't open a UI window.
tart run my-test-vm --vnc                     # Use screen sharing instead of the built-in UI.
tart run my-test-vm --vnc-experimental        # Use Virtualization.Framework's VNC server instead of the built-in UI. 
tart help run                                 # tart run manual pages for all other options
``` 

## Tart tips

- Use `--random-serial` and `--random-mac` to avoid collisions across clones.
- `tart run` supports headful workflows; pair with `--display-refit` during OS first boot if needed.

## 📚 References

- [The Cookbook: Baking up your perfect Jamf Pro Test VM](https://www.motionbug.com/the-cookbook-baking-up-your-perfect-jamf-pro-test-vm/)
- [Packer Docs](https://developer.hashicorp.com/packer/docs)
- [Tart](https://tart.run)
