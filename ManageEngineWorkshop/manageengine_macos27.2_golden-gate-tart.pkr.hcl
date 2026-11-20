packer {
  required_plugins {
    tart = {
      version = ">= 1.16.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}
// Mac Admins India x ManageEngine Endpoint Central workshop (12 Dec 2026)
// macOS Golden Gate 27.2 base VM: no MDM profile or enrollment is created. Enroll in
// Endpoint Central during the workshop.
// HOST REQUIREMENT: the Mac running this build must be on macOS 27.2 or later.
// Run ./check-host.sh first.
// Golden Gate (macOS 27) provisions the local account and enables remote
// login via Tart's --provisioning-opts before first boot, instead of typing
// it in through Setup Assistant like the Sequoia/Tahoe templates do. That
// makes this boot_command much shorter, but it also means:
//   - Requires Tart CLI 2.33.0+ and macOS 27+ on both the host and guest VM.
//   - "Sharing" is no longer in the System Settings View menu; it's opened
//     via the x-apple.systempreferences:com.apple.Sharing-Settings.extension
//     URL scheme instead.

# -------------------------
# Variables
# -------------------------

variable "vm_name" {
  type        = string
  default     = "goldengate-workshop-272"
  description = "Name of the virtual machine to create"
}

variable "ipsw_url" {
  type        = string
  default     = "https://updates.cdn-apple.com/2026FallFCS/c9671975-52db-4fb5-9af2-00217169ba8d/UniversalMac_27.2_26B123_Restore.ipsw"
  description = "URL to the macOS IPSW file"
}

variable "account_userName" {
  type        = string
  default     = "admin"
  description = "Name of the macOS local account"
}

variable "account_password" {
  type        = string
  sensitive   = true
  default     = "admin"
  description = "Password for the macOS local account"
}


# Feature toggles for optional steps
variable "enable_auto_login" {
  type        = bool
  default     = true
  description = "Enable auto-login for the final image. Provisioning always logs in automatically (required to reach the desktop and complete this build); if false, auto-login is turned back off afterward in the build's shell provisioner."
}

# Feature toggles for optional steps
variable "enable_passwordless_sudo" {
  type        = bool
  default     = true
  description = "Enable passwordless sudo (required for other steps below that call sudo non-interactively)"
}

variable "enable_spotlight_disable" {
  type        = bool
  default     = true
  description = "Disable Spotlight indexing"
}

variable "enable_safari_automation" {
  type        = bool
  default     = true
  description = "Enable Safari automation setup"
}

variable "enable_screenlock_disable" {
  type        = bool
  default     = true
  description = "Enable screen lock for the user"
}

variable "enable_clipboard_sharing" {
  type        = bool
  default     = true
  description = "Enable clipboard sharing"
}

# -------------------------
# Source Definition
# -------------------------

source "tart-cli" "tart" {
  from_ipsw    = var.ipsw_url
  vm_name      = var.vm_name
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 100
  # Sparse/thin-provisioned disk format; requires macOS 26+ host and Tart v26+
  disk_format  = "asif"
  ssh_username = "${var.account_userName}"
  ssh_password = "${var.account_password}"
  ssh_timeout  = "180s"

  # Creates the local account and enables remote login before first boot,
  # instead of typing it into Setup Assistant.
  #
  # logsInAutomatically is always true here regardless of enable_auto_login:
  # it's the only way this VM ever reaches a desktop on first boot (there's
  # no Setup Assistant step to fall back on), and boot_command below depends
  # on that desktop existing. enable_auto_login instead controls whether
  # auto-login is turned back off afterward, in the build's shell provisioner.
  run_extra_args = [
    "--provisioning-opts=${join(",", [
      "fullName=${var.account_userName}",
      "username=${var.account_userName}",
      "password=${var.account_password}",
      "enablesRemoteLogin=true",
      "logsInAutomatically=true",
    ])}",
  ]

  # Automates the remaining post-account-creation setup
  boot_command = [
    # Wait for first-boot provisioning to finish automatic login
    "<wait120s>",
    # Enable keyboard navigation (for later system tweaks)
    "<wait10s><leftAltOn><spacebar><leftAltOff>Terminal<wait10s><enter>",
    "<wait10s><wait10s>defaults write NSGlobalDomain AppleKeyboardUIMode -int 3<enter>",
    # Disable Gatekeeper via Terminal
    "<wait10s>sudo spctl --global-disable<enter>",
    "<wait10s>${var.account_password}<enter>",
    # Disable Gatekeeper via System Settings
    # On Golden Gate opening System Settings through Spotlight is not very reliable, sometimes opens System information
    "<wait10s>open '/System/Applications/System Settings.app'<enter>",
    "<wait120s>",
    "<wait10s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Privacy & Security<enter>",
    "<wait10s><leftShiftOn><tab><tab><tab><tab><tab><tab><leftShiftOff>",
    "<wait10s><down><wait1s><down><wait1s><enter>",
    "<wait10s>${var.account_password}<enter>",
    "<wait10s><leftShiftOn><tab><leftShiftOff><wait1s><spacebar>",
    # Quit System Settings
    "<wait10s><leftAltOn>q<leftAltOff>",
    # Refocus Terminal after quitting System Settings
    "<wait10s><leftAltOn><spacebar><leftAltOff>Terminal<wait10s><enter>",
    # Sharing is no longer listed in the View menu on Golden Gate
    "<wait10s>open 'x-apple.systempreferences:com.apple.Sharing-Settings.extension'<enter>",
    # Enable Screen Sharing through the UI to grant the required TCC permissions
    "<wait10s><tab><tab><tab><tab><tab><tab><spacebar>",
    "<wait10s>${var.account_password}<enter>",
    # Quit System Settings
    "<wait10s><leftAltOn>q<leftAltOff>",
  ]

  create_grace_time  = "30s"
  recovery_partition = "keep"
}

# -------------------------
# Build Section
# -------------------------
build {
  sources = ["source.tart-cli.tart"]

  provisioner "shell" {
    inline = [
      "set -euxo pipefail",

      # Passwordless sudo
      "if [ \"${var.enable_passwordless_sudo}\" = \"true\" ]; then",
      "  echo \"Enabling passwordless sudo for ${var.account_userName}...\"",
      "  echo \"${var.account_password}\" | sudo -S sh -c \"mkdir -p /etc/sudoers.d/; echo '${var.account_userName} ALL=(ALL) NOPASSWD: ALL' | EDITOR=tee visudo /etc/sudoers.d/${var.account_userName}-nopasswd\"",
      "fi",

      # Auto-login was forced on for provisioning (see run_extra_args); turn
      # it back off now if the caller didn't actually want it on the final image
      "if [ \"${var.enable_auto_login}\" != \"true\" ]; then",
      "  echo \"Disabling auto-login (enable_auto_login=false)...\"",
      "  sudo defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser",
      "fi",

      # Screensaver disable (always on)
      "echo \"Disabling screensaver...\"",
      "sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime 0",
      "defaults -currentHost write com.apple.screensaver idleTime 0",

      # Prevent sleep (always on)
      "echo \"Preventing system sleep...\"",
      "sudo systemsetup -setsleep Off 2>/dev/null",

      # Safari automation
      "if [ \"${var.enable_safari_automation}\" = \"true\" ]; then",
      "   echo \"Enabling Safari automation...\"",
      "   /Applications/Safari.app/Contents/MacOS/Safari &",
      "   SAFARI_PID=$!",
      "   disown",
      "   sleep 30",
      "   kill -9 \"$SAFARI_PID\" || true",
      "   sudo safaridriver --enable",
      "fi",

      # Screen lock disable
      "if [ \"${var.enable_screenlock_disable}\" = \"true\" ]; then",
      "   echo \"Disabling screen lock...\"",
      "   sysadminctl -screenLock off -password \"${var.account_password}\"",
      "fi",

      # Spotlight disable
      "if [ \"${var.enable_spotlight_disable}\" = \"true\" ]; then",
      "   echo \"Disabling Spotlight indexing...\"",
      "   sudo mdutil -a -i off",
      "fi",

      # Install Tart guest agent
      "if [ \"${var.enable_clipboard_sharing}\" = \"true\" ]; then",
      "   echo \"Installing tart guest agent to enable Clipboard sharing...\"",
      "   /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"",
      "   /opt/homebrew/bin/brew tap openai/tools",
      "   /opt/homebrew/bin/brew trust openai/tools || true",
      "   /opt/homebrew/bin/brew install openai/tools/tart-guest-agent",
      "   curl -f https://raw.githubusercontent.com/cirruslabs/macos-image-templates/refs/heads/main/data/tart-guest-agent.plist -o tart-guest-agent.plist",
      "   sudo mv tart-guest-agent.plist /Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist",
      "   sudo chown -R root:wheel /Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist",
      "fi",

      # Set ComputerName
      " computerName=\"VM-TART-$(jot -r 1 1000 9999)\"",
      " sudo scutil --set HostName $computerName",
      " sudo scutil --set LocalHostName $computerName",
      " sudo scutil --set ComputerName $computerName",
    ]
  }
}
