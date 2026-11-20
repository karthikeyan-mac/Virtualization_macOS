# macOS Virtual Machine for testing using Packer and Tart

This repository contains Packer configurations for building **macOS virtual machines on Apple Silicon** that create an enrollment profile for **Jamf Pro** or install the **Microsoft Intune Company Portal** for testing.

It's inspired by [MotionBug's "The Cookbook: Baking up your perfect Jamf Pro Test VM"](https://www.motionbug.com/the-cookbook-baking-up-your-perfect-jamf-pro-test-vm/) and uses Apple's **Virtualization framework** with Packer to simulate real-world MDM environments.

---

### What is Packer?

[Packer](https://developer.hashicorp.com/packer) is a tool that lets you create identical machine images for multiple platforms from a single source template. Packer can create golden images to use in image pipelines.

### What is tart?

[Tart](https://tart.run) is a virtualization toolset to build, run and manage macOS and Linux virtual machines on Apple Silicon. Tart uses Apple's own [Virtualization.Framework](https://developer.apple.com/documentation/virtualization) for near-native performance.

**Note**: macOS 26.1 has an Apple bug where VM serial numbers come back empty, blocking MDM enrollment. It's fixed in macOS 26.2, which is the build the Tahoe template targets.

## Features

- **Three macOS versions, one workflow** — dedicated templates for Sequoia, Tahoe, and Golden Gate, each producing a ready-to-clone Tart VM image.
- **Fully hands-off provisioning** — Setup Assistant is driven end-to-end via Tart's `boot_command` keystrokes on Sequoia/Tahoe; Golden Gate instead creates the account directly through Tart's `--provisioning-opts`, skipping Setup Assistant entirely.
- **MDM enrollment, your choice of vendor** — generates a Jamf Pro `.mobileconfig` enrollment profile on the Desktop (with a fresh UUID, your invitation ID, and Jamf URL baked in), downloads and silently installs the Microsoft Intune Company Portal, or skips MDM altogether — controlled by a single `mdm_vendor` variable.
- **Configurable local account** — username and password are both variables, applied consistently across SSH access, account creation, and every automated step that needs to authenticate.
- **Auto-login** — the created account logs in automatically on boot, toggleable.
- **Passwordless sudo** — grants the account NOPASSWD sudo via `sudoers.d`, so the rest of the build (and any post-build automation) can run privileged commands non-interactively.
- **Gatekeeper disabled** — both via `spctl --global-disable` and by walking through the Privacy & Security confirmation in System Settings, so unsigned/ad-hoc test builds run without friction.
- **Remote access enabled** — Screen Sharing and Remote Login (SSH) are turned on during setup, so the VM is reachable the moment it boots.
- **Spotlight indexing disabled** — toggleable, reduces background CPU/disk load in lab VMs.
- **Safari pre-automated** — launches Safari once to populate its defaults and enables `safaridriver`, so Safari-based automation/testing works immediately.
- **Screen lock disabled** — toggleable, keeps the session unlocked for unattended lab use.
- **System sleep prevented** — the VM won't sleep mid-test.
- **Clipboard sharing** — installs the Tart Guest Agent (from the `openai/tools` Homebrew tap, which the build trusts automatically) so copy/paste works between host and guest, toggleable.
- **Unique Computer Name** — sets a random `VM-TART-XXXX` hostname on every build, avoiding name collisions across clones.
- **Thin-provisioned disks** — Tahoe and Golden Gate use Tart's `asif` disk format for a smaller on-disk image footprint.
- **Recovery partition kept** — so `softwareupdate` still works inside the finished VM.
- **Everything overridable** — every credential, URL, and toggle above is a Packer variable, so a single template file supports many different builds via `-var`/`-var-file` at build time.

## Available templates

| File | Target macOS | Default `vm_name` | Setup method |
|---|---|---|---|
| `macos15.6.1_sequoia-tart.pkr.hcl` | 15.6.1 (24G90) | `sequoia-jamfdev-1561` | Setup Assistant `boot_command` keystrokes |
| `macos26.6.2_tahoe-tart.pkr.hcl` | 26.6.2 (25G83) | `tahoe-jamfdev-266` | Setup Assistant `boot_command` keystrokes |
| `macos27.2_golden-gate-tart.pkr.hcl` | 27.2 (26B123) | `goldengate-jamfdev-272` | Tart's `--provisioning-opts` (no Setup Assistant); requires Tart CLI ≥ 2.33.0 and macOS 27+ on the host |

> **⚠️ Known issue: macOS 27 (Golden Gate) MDM enrollment.** macOS 27 currently has issues with MDM enrollment. This is reported to be fixed in **macOS 27.3 beta**. Until then, MDM enrollment on the Golden Gate VM may not work; use Sequoia or Tahoe if you need to enroll.

## Prerequisites

- Apple Silicon
- [Homebrew](https://brew.sh)
- Packer ≥ 1.16 and Tart ≥ 1.16.0 (Sequoia/Tahoe); the Golden Gate template needs Tart CLI ≥ 2.33.0 for `--provisioning-opts` and a macOS 27+ host.
- Jamf Pro access to create enrollment invitations (only needed if `mdm_vendor = jamf`).
- Internet connectivity for IPSW and Homebrew installs.
- IPSW Links: [mrmacintosh.com's Apple Silicon IPSW database](https://mrmacintosh.com/apple-silicon-m1-full-macos-restore-ipsw-firmware-files-database/)

## 1. Install tools

```
brew install openai/tools/tart
brew tap hashicorp/tap
brew install hashicorp/tap/packer
```

## 2. Configuration Variables in packer file

### Core variables
| Name | Type | Description |
|---|---|---|
| `vm_name` | string | Name of the VM to create. Default differs per template — see the table above. |
| `ipsw_url` | string | macOS IPSW restore image URL used to build the VM. Each template pins the build it was verified against; get newer builds from [mrmacintosh.com](https://mrmacintosh.com/apple-silicon-m1-full-macos-restore-ipsw-firmware-files-database/). |
| `account_userName` | string | Local macOS account username created during setup. Default: `admin`. |
| `account_password` | string (sensitive) | Local macOS account password. Default: `karthik123` — override via `-var` or a var-file rather than relying on the checked-in default. |
| `mdm_vendor` | string | `jamf` or `intune` (case-insensitive). Set it to anything else, e.g. `none`, to skip MDM enrollment entirely. |
| `jamf_url` | string | Jamf Cloud URL. Default: `https://karthik.jamfcloud.com`. |
| `mdm_invitation_id` | string | Jamf Pro enrollment invitation ID; only used when `mdm_vendor = jamf`. Default is the placeholder `REPLACE_WITH_INVITATION_ID` — set your own via `-var` or edit the file. |

### Feature toggles
| Name | Type | Default | Description |
|---|---|---|---|
| `enable_auto_login` | bool | true | Enables automatic login for the specified user. On the Golden Gate template, login always happens once during provisioning (required to reach the desktop and complete the build) — this toggle only controls whether it's still enabled on the finished image. |
| `enable_passwordless_sudo` | bool | true | Grants passwordless sudo to the specified user via `sudoers.d`. Several steps later in the build assume this is on and call `sudo` non-interactively — turning it off without another way to authenticate will stall those steps. |
| `enable_spotlight_disable` | bool | true | Disables Spotlight indexing to reduce background load in lab VMs. |
| `enable_safari_automation` | bool | true | Launches Safari once and enables `safaridriver` for automation. |
| `enable_screenlock_disable` | bool | true | Disables screen lock for the specified user. |
| `enable_clipboard_sharing` | bool | true | Installs Tart Guest Agent (`brew install openai/tools/tart-guest-agent`) to enable host–guest clipboard sharing. |

## 3. 🔑Getting Your Jamf Invitation ID (if JAMF is your MDM)

1. Log in to Jamf Pro → **Computers → PreStage Enrollments → Invitations**
2. Create a new invitation.
3. Copy the URL that looks like:
   `https://your.jamfcloud.com/enroll?invitation=XXXXXXXXXXXX`
4. The part after `invitation=` is your **Invitation ID**.
5. Add it to the `mdm_invitation_id` variable.

---

## 4.🧑‍💻Building the VM

```bash
packer init macos26.6.2_tahoe-tart.pkr.hcl
packer validate macos26.6.2_tahoe-tart.pkr.hcl
packer build macos26.6.2_tahoe-tart.pkr.hcl
```
Replace with `macos15.6.1_sequoia-tart.pkr.hcl` or `macos27.2_golden-gate-tart.pkr.hcl` to build the Sequoia or Golden Gate image instead.

### Override variable at runtime (build)
```bash
packer build -var="account_userName=macadmin" -var="account_password=supersecurepass" -var="enable_auto_login=true" macos26.6.2_tahoe-tart.pkr.hcl
```

🟥 $${\color{Red}Note:}$$ No interaction required. Once the image finishes installing, Tart starts the VM and runs the automated setup. Avoid clicking or typing in the VM and allow the build to finish.

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

## Previous versions

Older, known-working templates are kept in [`previous_versions/`](previous_versions/) for anyone who needs an earlier build:

| File | Target macOS | Default `vm_name` |
|---|---|---|
| `previous_versions/macos27.0_golden-gate-tart.pkr.hcl` | 27.0 (26A428) | `goldengate-jamfdev-270` |
| `previous_versions/macos26.2_tahoe-tart.pkr.hcl` | 26.2 (25C56) | `tahoe-jamfdev-261` |
