# Mac Admins India × ManageEngine Endpoint Central Workshop — VM Setup

Bengaluru · Saturday, 12 December 2026 · Aloft Bengaluru Outer Ring Road

Build a clean macOS virtual machine on your own Mac **before the workshop** so you can enroll it in ManageEngine Endpoint Central during the hands-on session. These templates create a plain VM with a local admin account. They include **no MDM profile or enrollment**; you'll do that in the workshop.

## Pick your VM

| Template | VM you get | Host Mac must be on | Default VM name |
|---|---|---|---|
| `manageengine_macos26.6.2_tahoe-tart.pkr.hcl` | macOS Tahoe **26.6.2** | **macOS 26.6.2 or later** | `tahoe-workshop-266` |
| `manageengine_macos27.2_golden-gate-tart.pkr.hcl` | macOS Golden Gate **27.2** | **macOS 27.2 or later** | `goldengate-workshop-272` |

You only need one. Choose whichever you want to practise on.

## ⚠️ Your Mac's OS must be the same or newer than the VM

A Mac cannot create a VM that runs a newer macOS than its own. Check your version first (Apple menu → About This Mac, or run `sw_vers -productVersion`).

| Your Mac runs | Can build Tahoe 26.6.2 VM? | Can build Golden Gate 27.2 VM? |
|---|---|---|
| macOS 26.2 | ❌ No. Update to 26.6.2 or later | ❌ No |
| macOS 26.6.2 or any later 26.x | ✅ Yes | ❌ No (needs 27.2 or later) |
| macOS 27.0 | ✅ Yes | ❌ No. Update to 27.2 or later |
| macOS 27.2 or later | ✅ Yes | ✅ Yes |

If you're below the required version, update first: **System Settings → General → Software Update**. Do this at home rather than at the venue, as updates are large.

The script `check-host.sh` does this check for you (see step 3).

## Requirements

- **Apple silicon Mac** (M1 or later). Intel Macs can't run these VMs.
- Host macOS version as in the tables above.
- **At least 16 GB RAM** (the VM uses 8 GB) and **60 GB or more free disk space**. The IPSW download is about 17 GB, and the VM disk is thin-provisioned (it grows as used, up to 100 GB).
- [Homebrew](https://brew.sh)
- Good internet. Run the build **at home**, not on venue Wi-Fi.
- Golden Gate (27.2) template only: **Tart CLI 2.33.0 or later**.

## Steps

### 1. Install the tools

```bash
brew install cirruslabs/cli/tart hashicorp/tap/packer
tart --version      # Golden Gate template needs 2.33.0 or later
```

### 2. Get these files

```bash
git clone https://github.com/karthikeyan-mac/Virtualization_macOS.git
cd Virtualization_macOS/ManageEngineWorkshop
```

### 3. Check your Mac can build the VM

```bash
./check-host.sh 26    # for the Tahoe 26.6.2 VM
./check-host.sh 27    # for the Golden Gate 27.2 VM
```

It must print `OK`. If it prints `FAIL`, update macOS (see above) before continuing.

### 4. Build the VM

Tahoe 26.6.2:

```bash
packer init manageengine_macos26.6.2_tahoe-tart.pkr.hcl
packer build manageengine_macos26.6.2_tahoe-tart.pkr.hcl
```

Golden Gate 27.2:

```bash
packer init manageengine_macos27.2_golden-gate-tart.pkr.hcl
packer build manageengine_macos27.2_golden-gate-tart.pkr.hcl
```

The build downloads the IPSW, installs macOS and sets up the account, which takes **30–60 minutes**.

**Don't touch the keyboard or mouse, or close the VM window, while it runs.** On Tahoe the build types into Setup Assistant for you. Interacting with the VM will break it.

### 5. Start the VM

```bash
tart list                          # confirm your VM is there
tart run tahoe-workshop-266        # or: tart run goldengate-workshop-272
```

Log in (auto-login is on) with:

- **Username:** `admin`
- **Password:** `admin`

### 6. Bring it to the workshop

Bring your Mac **charged**, with the VM built and tested. Enrollment in ManageEngine Endpoint Central will be covered during the hands-on session.

## Clone & Run VM

Keep the VM you built as a clean original and work on a clone. Replace `tahoe-workshop-266` with your VM's name (`tart list` shows it).

```bash
# Clone your VM
tart clone tahoe-workshop-266 prod-test-vm

# Give the clone a random serial number and MAC address, and fit the display to the window
tart set prod-test-vm --display-refit --random-serial --random-mac

# Run it, sharing your home folder (appears in the VM at /Volumes/My Shared Files/SharedFolder)
tart run prod-test-vm --dir=SharedFolder:~
```

For more options, see the [main README](../README.md).

## Troubleshooting

| Problem | Fix |
|---|---|
| `check-host.sh` prints FAIL | Your Mac's macOS is older than the VM. Update it. |
| Build fails or hangs partway | Delete the half-built VM (`tart delete <vm-name>`) and run the build again. |
| Out of disk space | Free up 60 GB or more, then retry. Delete failed VMs with `tart delete`. |

Need help? Ask in the Mac Admins India community channel before the event.
