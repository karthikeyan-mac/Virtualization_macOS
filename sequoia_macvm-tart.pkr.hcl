packer {
  required_plugins {
    tart = {
      version = ">= 1.12.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}


# -------------------------
# Variables
# -------------------------

variable "vm_name" {
  type        = string
  default     = "sequoia-jamfdev-1561"
  description = "Name of the virtual machine to create"
}

variable "ipsw_url" {
  type        = string
  default     = "https://updates.cdn-apple.com/2025SummerFCS/fullrestores/093-10809/CFD6DD38-DAF0-40DA-854F-31AAD1294C6F/UniversalMac_15.6.1_24G90_Restore.ipsw"
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
  default     = "karthik123"
  description = "Password for the macOS local account"
}

variable "mdm_vendor" {
  type        = string
  default     = "intune"
  description = "Jamf/Intune"
}

variable "jamf_url" {
  type        = string
  default     = "https://karthik.jamfcloud.com"
  description = "Jamf Cloud URL"
}

variable "mdm_invitation_id" {
  type        = string
  default     = "2698309539233484577234274464940158018634"
  description = "MDM enrollment invitation ID"
}


# Feature toggles for optional steps
variable "enable_auto_login" {
  type        = bool
  default     = true
  description = "Enable auto-login for the user"
}

# Feature toggles for optional steps
variable "enable_passwordless_sudo" {
  type        = bool
  default     = true
  description = "Enable passwordless duo"
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
# Locals
# -------------------------

locals {
  uuid = uuidv4()
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
  ssh_username = "${var.account_userName}"
  ssh_password = "${var.account_password}"
  ssh_timeout  = "300s"

  # Automates macOS Setup Assistant
  boot_command = [
    "<wait60s><spacebar>",
    # Language selection: workaround by switching to Italiano first, then English
    "<wait30s>italiano<esc>english<wait2s><enter>",
    # Select Country/Region
    "<wait30s>united states<leftShiftOn><tab><leftShiftOff><wait4s><spacebar>",
    # Transfer Your Data → Skip
    "<wait10s><tab><tab><tab><spacebar><tab><tab><wait4s><spacebar>",
    # Written and Spoken Languages → Continue
    "<wait10s><leftShiftOn><tab><leftShiftOff><wait4s><spacebar>",
    # Accessibility → Continue
    "<wait10s><leftShiftOn><tab><leftShiftOff><wait4s><spacebar>",
    # Data & Privacy → Continue
    "<wait10s><leftShiftOn><tab><leftShiftOff><wait4s><spacebar>",
    # Create a Mac Account
    "<wait10s>${var.account_userName}<tab>${var.account_userName}<tab>${var.account_password}<tab>${var.account_password}<tab><tab><spacebar><tab><tab><spacebar>",
    # Enable Voice Over (then disable later)
    "<wait120s><leftAltOn><f5><leftAltOff>",
    # Skip Apple ID sign-in
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    "<wait10s><tab><spacebar>",
    # Terms and Conditions → Agree
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    "<wait10s><tab><spacebar>",
    # Location Services → Skip
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    "<wait10s><tab><spacebar>",
    # Time Zone → Set UTC
    "<wait10s><tab><tab>UTC<enter><leftShiftOn><tab><tab><leftShiftOff><spacebar>",
    # Analytics → Skip
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Screen Time → Skip
    "<wait10s><tab><spacebar>",
    # Siri → Skip
    "<wait10s><tab><spacebar><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Choose Look → Default
    "<wait10s><leftShiftOn><tab><leftShiftOff><spacebar>",
    # Auto Update → Enable
    "<wait10s><tab><spacebar>",
    # Welcome Screen → Enter Desktop
    "<wait10s><spacebar>",
    # Disable Voice Over
    "<leftAltOn><f5><leftAltOff>",
    # Enable keyboard navigation (for later system tweaks)
    "<wait10s><leftAltOn><spacebar><leftAltOff>Terminal<enter>",
    "<wait10s>defaults write NSGlobalDomain AppleKeyboardUIMode -int 3<enter>",
    "<wait10s><leftAltOn>q<leftAltOff>",
    # Open System Settings → Sharing
    "<wait10s><leftAltOn><spacebar><leftAltOff>System Settings<enter>",
    "<wait10s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Sharing<enter>",
    # Enable Screen Sharing
    "<wait10s><tab><tab><tab><tab><tab><tab><tab><spacebar>",
    # Enable Remote Login
    "<wait30s><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><tab><spacebar>",
    "<wait10s><leftAltOn>q<leftAltOff>",
    # Disable Gatekeeper via Terminal
    "<wait10s><leftAltOn><spacebar><leftAltOff>Terminal<enter>",
    "<wait10s>sudo spctl --global-disable<enter>",
    "<wait10s>${var.account_password}<enter>",
    "<wait10s><leftAltOn>q<leftAltOff>",
    # Disable Gatekeeper via System Settings
    "<wait10s><leftAltOn><spacebar><leftAltOff>System Settings<enter>",
    "<wait10s><leftCtrlOn><f2><leftCtrlOff><right><right><right><down>Privacy & Security<enter>",
    "<wait10s><down><wait1s><down><wait1s><enter>",
    "<wait10s>${var.account_password}<enter>",
    "<wait10s><leftShiftOn><tab><leftShiftOff><wait1s><spacebar>",
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
    in
    = [
      "set -euxo pipefail",

      # Passwordless sudo
      "if [ \"${var.enable_passwordless_sudo}\" = \"true\" ]; then",
      "  echo \"Enabling passwordless sudo for ${var.account_userName}...\"",
      "  echo ${var.account_password} | sudo -S sh -c \"mkdir -p /etc/sudoers.d/; echo '${var.account_userName} ALL=(ALL) NOPASSWD: ALL' | EDITOR=tee visudo /etc/sudoers.d/${var.account_userName}-nopasswd\"",
      "fi",

      # Auto-login
      "if [ \"${var.enable_auto_login}\" = \"true\" ]; then",
      "   curl https://raw.githubusercontent.com/karthikeyan-mac/Virtualization_macOS/refs/heads/main/kcpasswordgen.sh -o /tmp/kcpasswordgen.sh",
      "   encoded_value=\"$(bash /tmp/kcpasswordgen.sh ${var.account_password})\"",
      "   echo \"Enabling passwordless login\"",
      "   echo \"$encoded_value\" | sudo xxd -r - /etc/kcpassword",
      "   echo \"$encoded_value\"",
      "   sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser ${var.account_userName}",
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
      "   kill -9 $SAFARI_PID",
      "   sudo safaridriver --enable",
      "fi",

      # Screen lock disable
      "if [ \"${var.enable_screenlock_disable}\" = \"true\" ]; then",
      "   echo \"Disabling screen lock...\"",
      "   sysadminctl -screenLock off -password ${var.account_password}",
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
      "    /opt/homebrew/bin/brew install cirruslabs/cli/tart-guest-agent",
      "   curl https://raw.githubusercontent.com/cirruslabs/macos-image-templates/refs/heads/main/data/tart-guest-agent.plist -o tart-guest-agent.plist",
      "   sudo mv tart-guest-agent.plist /Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist",
      "   sudo chown -R root:wheel /Library/LaunchAgents/org.cirruslabs.tart-guest-agent.plist",
      "fi",
      
      # Set ComputerName
      " computerName=\"VM-TART-$(jot -r 1 1000 9999)\"",
      " sudo scutil --set HostName $computerName",
      " sudo scutil --set LocalHostName $computerName",
      " sudo scutil --set ComputerName $computerName",

      # Generate MDM profile
      // Create MDM enrollment profile
      "if [ \"${var.mdm_vendor}\" = \"jamf\" ]; then",
      "  echo \"Creating MDM Profile on Desktop\"",
      "cat << EOF > ~/Desktop/mdm_enroll.mobileconfig",
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">",
      "<plist version=\"1.0\">",
      "    <dict>",
      "        <key>PayloadUUID</key>",
      "        <string>${local.uuid}</string>",
      "        <key>PayloadOrganization</key>",
      "        <string>JAMF Software</string>",
      "        <key>PayloadVersion</key>",
      "        <integer>1</integer>",
      "        <key>PayloadIdentifier</key>",
      "        <string>${local.uuid}</string>",
      "        <key>PayloadDescription</key>",
      "        <string>MDM Profile for mobile device management</string>",
      "        <key>PayloadType</key>",
      "        <string>Profile Service</string>",
      "        <key>PayloadDisplayName</key>",
      "        <string>MDM Profile</string>",
      "        <key>PayloadContent</key>",
      "        <dict>",
      "            <key>Challenge</key>",
      "            <string>${var.mdm_invitation_id}</string>",
      "            <key>URL</key>",
      "            <string>${var.jamf_url}/enroll/profile</string>",
      "            <key>DeviceAttributes</key>",
      "            <array>",
      "                <string>UDID</string>",
      "                <string>PRODUCT</string>",
      "                <string>SERIAL</string>",
      "                <string>VERSION</string>",
      "                <string>DEVICE_NAME</string>",
      "                <string>COMPROMISED</string>",
      "            </array>",
      "        </dict>",
      "    </dict>",
      "</plist>",
      "EOF",
      "fi",
      "if [ \"${var.mdm_vendor}\" = \"intune\" ]; then",
      "   echo \"Downloading and installing the Intune Company Portal\"",
      "   curl -L -o CompanyPortal-Installer.pkg \"https://go.microsoft.com/fwlink/?linkid=853070\"",
      "   sleep 10",
      "   sudo installer -pkg CompanyPortal-Installer.pkg -target /",
      "fi",
    ]
  }
}
