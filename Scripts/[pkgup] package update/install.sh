#!/usr/bin/env bash
# ============================================
#   PKGUP INSTALLER
#   Package Update System for Linux
#   Author: Ayoub (RDXFGXY1)
# ============================================
set -euo pipefail

# -------------------------
#  CONFIGURATION
# -------------------------
INSTALL_DIR="/usr/local/lib/pkgup"
BIN_DIR="/usr/local/bin"
COMMAND_NAME="pkgup"  # Change this to customize the command name!

# -------------------------
#  COLORS
# -------------------------
ESC='\033['
RESET="${ESC}0m"
BOLD="${ESC}1m"
RED="${ESC}31m"
GREEN="${ESC}32m"
YELLOW="${ESC}33m"
CYAN="${ESC}36m"
BLUE="${ESC}34m"

# -------------------------
#  HELPER FUNCTIONS
# -------------------------
print_header() {
  clear
  echo -e "${CYAN}${BOLD}"
  cat << "EOF"
  ╔═══════════════════════════════════════════════╗
  ║                                               ║
  ║           📦  PKGUP INSTALLER  📦            ║
  ║                                               ║
  ║      Package Update System for Linux         ║
  ║                                               ║
  ╚═══════════════════════════════════════════════╝
EOF
  echo -e "${RESET}"
}

log_info() {
  echo -e "${CYAN}[INFO]${RESET} $*"
}

log_success() {
  echo -e "${GREEN}[✓]${RESET} $*"
}

log_warning() {
  echo -e "${YELLOW}[!]${RESET} $*"
}

log_error() {
  echo -e "${RED}[✗]${RESET} $*"
}

check_root() {
  if [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root!"
    log_info "Run it as a normal user. It will ask for sudo when needed."
    exit 1
  fi
}

check_sudo() {
  log_info "Checking sudo privileges..."
  if ! sudo -v; then
    log_error "This script requires sudo privileges to install."
    exit 1
  fi
  log_success "Sudo access confirmed"
}

check_dependencies() {
  log_info "Checking dependencies..."
  
  local missing=()
  
  if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
    missing+=("wget or curl")
  fi
  
  if ! command -v tar >/dev/null 2>&1; then
    missing+=("tar")
  fi
  
  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Missing required tools: ${missing[*]}"
    echo
    log_info "Install them with your package manager:"
    log_info "  Debian/Ubuntu:  sudo apt install wget tar"
    log_info "  Arch Linux:     sudo pacman -S wget tar"
    log_info "  Fedora:         sudo dnf install wget tar"
    exit 1
  fi
  
  log_success "All dependencies satisfied"
}

create_directories() {
  log_info "Creating directories..."
  
  sudo mkdir -p "$INSTALL_DIR/modules"
  sudo mkdir -p "$INSTALL_DIR/logs"
  
  log_success "Directories created at $INSTALL_DIR"
}

# -------------------------
#  CREATE MAIN DISPATCHER
# -------------------------
create_dispatcher() {
  log_info "Creating main dispatcher: $COMMAND_NAME..."
  
  sudo tee "$BIN_DIR/$COMMAND_NAME" >/dev/null <<'DISPATCHER_EOF'
#!/usr/bin/env bash
# ============================================
#   PACKAGE UPDATE DISPATCHER
#   Usage: pkgup -u <package>
# ============================================
set -euo pipefail

MODULE_DIR="/usr/local/lib/pkgup/modules"
VERSION="1.0.0"

# Colors
ESC='\033['
RESET="${ESC}0m"
BOLD="${ESC}1m"
RED="${ESC}31m"
GREEN="${ESC}32m"
YELLOW="${ESC}33m"
CYAN="${ESC}36m"

show_help() {
  cat <<EOF
${BOLD}Package Update System v${VERSION}${RESET}

${CYAN}Usage:${RESET}
  pkgup -u <package>     Update a specific package
  pkgup --update <package>
  pkgup -l               List available packages
  pkgup --list
  pkgup -h               Show this help
  pkgup --help

${CYAN}Examples:${RESET}
  pkgup -u discord       Update Discord
  pkgup --update discord

${CYAN}Available packages:${RESET}
EOF
  if [ -d "$MODULE_DIR" ]; then
    for module in "$MODULE_DIR"/update-*; do
      if [ -x "$module" ]; then
        local pkg=$(basename "$module" | sed 's/^update-//')
        echo "  - $pkg"
      fi
    done
  else
    echo "  No modules found"
  fi
}

list_packages() {
  echo -e "${CYAN}${BOLD}Available Update Modules:${RESET}\n"
  if [ -d "$MODULE_DIR" ]; then
    local found=0
    for module in "$MODULE_DIR"/update-*; do
      if [ -x "$module" ]; then
        local pkg=$(basename "$module" | sed 's/^update-//')
        echo -e "  ${GREEN}✓${RESET} $pkg"
        found=1
      fi
    done
    if [ $found -eq 0 ]; then
      echo -e "${YELLOW}No modules installed yet${RESET}"
    fi
  else
    echo -e "${RED}Module directory not found${RESET}"
  fi
}

run_update() {
  local package="$1"
  local module="$MODULE_DIR/update-$package"
  
  if [ ! -f "$module" ]; then
    echo -e "${RED}Error:${RESET} Unknown package '$package'"
    echo -e "Run ${CYAN}pkgup -l${RESET} to see available packages"
    exit 1
  fi
  
  if [ ! -x "$module" ]; then
    echo -e "${RED}Error:${RESET} Module '$package' is not executable"
    exit 1
  fi
  
  echo -e "${CYAN}Running update for:${RESET} ${BOLD}$package${RESET}\n"
  exec "$module"
}

# Parse arguments
if [ $# -eq 0 ]; then
  show_help
  exit 0
fi

case "$1" in
  -u|--update)
    if [ $# -lt 2 ]; then
      echo -e "${RED}Error:${RESET} Package name required"
      echo "Usage: pkgup -u <package>"
      exit 1
    fi
    run_update "$2"
    ;;
  -l|--list)
    list_packages
    ;;
  -h|--help)
    show_help
    ;;
  *)
    echo -e "${RED}Error:${RESET} Unknown option '$1'"
    echo "Run 'pkgup --help' for usage"
    exit 1
    ;;
esac
DISPATCHER_EOF

  sudo chmod +x "$BIN_DIR/$COMMAND_NAME"
  log_success "Dispatcher created: $BIN_DIR/$COMMAND_NAME"
}

# -------------------------
#  CREATE DISCORD MODULE
# -------------------------
create_discord_module() {
  log_info "Creating Discord update module..."
  
  sudo tee "$INSTALL_DIR/modules/update-discord" >/dev/null <<'DISCORD_EOF'
#!/usr/bin/env bash
# ============================================
#   DISCORD AUTO-UPDATER
#   Author: Ayoub x ChatGPT
#   Version: 2.1
#   Usage: update-discord [--yes|-y]
# ============================================

# Parse arguments FIRST (before set -u)
SKIP_CONFIRM=false
if [ $# -gt 0 ]; then
  if [ "$1" = "--yes" ] || [ "$1" = "-y" ]; then
    SKIP_CONFIRM=true
  fi
fi

# Now enable strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
INSTALL_DIR="/opt/discord"
TMPDIR="$(mktemp -d -t discord-update.XXXXXX)"
DESKTOP_FILE="/usr/share/applications/discord.desktop"
LOGFILE="/var/log/update-discord.log"
VERSION_FILE="/opt/discord/resources/build_info.json"

# Colors
ESC='\033['
RESET="${ESC}0m"
BOLD="${ESC}1m"
RED="${ESC}31m"; GREEN="${ESC}32m"; YELLOW="${ESC}33m"; BLUE="${ESC}34m"
MAG="${ESC}35m"; CYAN="${ESC}36m"; WHITE="${ESC}37m"

# Rainbow helper
rainbow() {
  local text="$1"
  local i=0
  local colors=("${RED}" "${YELLOW}" "${GREEN}" "${CYAN}" "${BLUE}" "${MAG}")
  local out=""
  for ((i=0; i<${#text}; i++)); do
    local c="${text:i:1}"
    out+="${colors[$((i % ${#colors[@]}))]}${c}"
  done
  echo -e "${out}${RESET}"
}

log() {
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

cleanup() {
  rm -rf "$TMPDIR"
}
trap 'cleanup; log "Interrupted. Exiting."; echo -e "\n${RED}Update aborted.${RESET}"; exit 1' INT TERM

# ASCII Dragon
print_dragon() {
cat <<'DRAGON'
                       ___====-_  _-====___
                 _--^^^#####//      \\#####^^^--_
              _-^##########// (    ) \\##########^-_
             -############//  |\^^/|  \\############-
           _/############//   (@::@)   \\############\_
          /#############((     \\//     ))#############\
         -###############\\    (oo)    //###############-
        -#################\\  / VV \  //#################-
       -###################\\/      \//###################-
      _#/|##########/\######(   /\   )######/\##########|\#_
      |/ |#/\#/\#/\/  \#/\##\  /  \  /##/\#/  \/\#/\#/\#| \|
      `  |/  V  V  `   V  \\#\/\/\/\/#/  V   '  V  V  \|  '
         `   `  `      `   /  /    \  \   '      '  '   '
DRAGON
}

# Anime quotes
quotes=(
  "People's lives don't end when they die, it ends when they lose faith. - Itachi Uchiha"
  "Whatever you lose, you'll find it again. But what you throw away forever stays that way. - Kenshin Himura"
  "It's not the face that makes someone a monster; it's the choices they make with their lives. - Naruto Uzumaki"
  "To know sorrow is not terrifying. What is terrifying is to know you can't go back to happiness you could have. - Matsumoto Rangiku"
  "If you don't take risks, you can't create a future. - Monkey D. Luffy"
)

rand_quote() {
  local i=$((RANDOM % ${#quotes[@]}))
  echo "${quotes[$i]}"
}

# Spinner
spinner() {
  local pid="$1"
  local msg="$2"
  local delay=0.08
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r| %s" "$msg"
    sleep "$delay"
    printf "\r/ %s" "$msg"
    sleep "$delay"
    printf "\r- %s" "$msg"
    sleep "$delay"
    printf "\r\\ %s" "$msg"
    sleep "$delay"
  done
  printf "\r"
}

# Progress bar
progress_bar() {
  local seconds="$1"
  local msg="$2"
  local i=0
  printf "%s\n" "$msg"
  while [ $i -le "$seconds" ]; do
    local pct=$((i * 100 / seconds))
    local done=$((pct / 4))
    local left=$((25 - done))
    printf "\r["
    
    # Print filled blocks
    local j=0
    while [ $j -lt "$done" ]; do
      printf "█"
      j=$((j + 1))
    done
    
    # Print empty blocks
    j=0
    while [ $j -lt "$left" ]; do
      printf " "
      j=$((j + 1))
    done
    
    printf "] %3s%%" "$pct"
    i=$((i + 1))
    sleep 0.08
  done
  printf "\n"
}

# System info
print_sysinfo() {
  local host
  local os
  local kernel
  local uptime
  local shell
  local mem
  
  host="$(hostnamectl --static 2>/dev/null || hostname)"
  os="$(grep '^PRETTY_NAME' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '\"' || echo "Linux")"
  kernel="$(uname -r)"
  uptime="$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")"
  shell="$(basename "$SHELL")"
  mem="$(free -h 2>/dev/null | awk '/Mem:/ {print $3 " / " $2}' || echo "unknown")"
  
  echo -e "${CYAN}┌────────────────────────────────────────────────────┐${RESET}"
  echo -e " ${BOLD}Host:${RESET} $host    ${BOLD}OS:${RESET} $os"
  echo -e " ${BOLD}Kernel:${RESET} $kernel    ${BOLD}Uptime:${RESET} $uptime"
  echo -e " ${BOLD}Shell:${RESET} $shell    ${BOLD}Memory:${RESET} $mem"
  echo -e "${CYAN}└────────────────────────────────────────────────────┘${RESET}"
}

# Check requirements
check_requirements() {
  log "Checking requirements..."
  if command -v wget >/dev/null 2>&1; then
    DL_CMD="wget"
  elif command -v curl >/dev/null 2>&1; then
    DL_CMD="curl"
  else
    echo -e "${RED}Error: neither wget nor curl is installed.${RESET}"
    exit 1
  fi
  return 0
}

# Get current installed version
get_current_version() {
  if [ -f "$VERSION_FILE" ]; then
    local version
    version=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$VERSION_FILE" 2>/dev/null || echo "unknown")
    echo "$version"
  else
    echo "not installed"
  fi
}

# Get latest available version from Discord
get_latest_version() {
  local temp_dir
  temp_dir=$(mktemp -d)
  local version="unknown"
  
  # Download just the version info (much smaller/faster)
  if curl -sL "https://discord.com/api/download?platform=linux&format=tar.gz" | tar -xz -C "$temp_dir" "Discord/resources/build_info.json" 2>/dev/null; then
    version=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$temp_dir/Discord/resources/build_info.json" 2>/dev/null || echo "unknown")
  fi
  
  rm -rf "$temp_dir"
  echo "$version"
}

# Ask for confirmation
confirm_action() {
  local prompt="$1"
  if [ "$SKIP_CONFIRM" = true ]; then
    return 0
  fi
  
  echo -e "${YELLOW}${prompt}${RESET}"
  read -p "Continue? [y/N] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "User cancelled operation"
    echo -e "${YELLOW}Operation cancelled.${RESET}"
    cleanup
    exit 0
  fi
}

# Main
main() {
  mkdir -p "$(dirname "$LOGFILE")"
  log "Starting Discord updater."
  clear
  print_dragon
  echo
  echo -e "$(rainbow " ██████  ██ ██████  ██████  ██████   ██████")"
  echo -e "$(rainbow "Updating Discord — GARUDA ASIAN DRAGON EDITION")"
  echo

  print_sysinfo
  echo
  echo -e "${MAG}Quote:${RESET} \"$(rand_quote)\""
  echo

  # Check current version
  local current_version
  current_version=$(get_current_version)
  echo -e "${CYAN}Current Discord version:${RESET} ${BOLD}$current_version${RESET}"
  
  # Check latest version available
  echo -e "${CYAN}Checking latest version...${RESET}"
  local latest_version
  latest_version=$(get_latest_version)
  echo -e "${CYAN}Latest Discord version:${RESET} ${BOLD}$latest_version${RESET}"
  echo
  
  # Compare versions
  if [ "$current_version" = "$latest_version" ] && [ "$latest_version" != "unknown" ] && [ "$current_version" != "not installed" ]; then
    echo -e "${GREEN}✓ Discord is already up to date!${RESET}"
    echo -e "${CYAN}You have the latest version: ${BOLD}$current_version${RESET}"
    confirm_action "Do you want to reinstall anyway?"
  elif [ "$current_version" = "not installed" ]; then
    echo -e "${YELLOW}Discord is not installed yet.${RESET}"
    confirm_action "Proceed with fresh installation?"
  else
    echo -e "${YELLOW}→ Update available: ${BOLD}$current_version${RESET} ${YELLOW}→${RESET} ${GREEN}${BOLD}$latest_version${RESET}"
    confirm_action "Proceed with update?"
  fi

  echo -ne "${CYAN}Checking connectivity to discord.com...${RESET} "
  if curl -sSfI https://discord.com >/dev/null 2>&1; then
    echo -e "${GREEN}OK${RESET}"
  else
    echo -e "${RED}Failed${RESET} — network or DNS problem."
    log "Network check failed."
    exit 1
  fi

  log "Downloading latest Discord tarball to $TMPDIR"
  echo -e "\n${YELLOW}Downloading latest Discord...${RESET}"
  
  # Download with proper command construction
  (
    if [ "$DL_CMD" = "wget" ]; then
      wget -q --show-progress --progress=bar:force -O "$TMPDIR/discord.tar.gz" "https://discord.com/api/download?platform=linux&format=tar.gz"
    else
      curl -L --progress-bar -o "$TMPDIR/discord.tar.gz" "https://discord.com/api/download?platform=linux&format=tar.gz"
    fi
  ) & dlpid=$!

  spinner "$dlpid" "Downloading..."
  wait "$dlpid" || { echo -e "${RED}Download failed.${RESET}"; log "Download failed."; exit 1; }
  echo -e "${GREEN}Download complete.${RESET}"
  log "Downloaded to $TMPDIR/discord.tar.gz"

  echo -e "${YELLOW}Extracting files...${RESET}"
  progress_bar 30 "Extracting (simulated progress bar)"
  tar -xzf "$TMPDIR/discord.tar.gz" -C "$TMPDIR"
  if [ ! -d "$TMPDIR/Discord" ]; then
    echo -e "${RED}Extraction failed.${RESET}" && log "Extraction failed." && exit 1
  fi
  log "Extraction OK."

  # Verify downloaded version
  local downloaded_version="unknown"
  if [ -f "$TMPDIR/Discord/resources/build_info.json" ]; then
    downloaded_version=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$TMPDIR/Discord/resources/build_info.json" 2>/dev/null || echo "unknown")
    echo -e "${CYAN}Downloaded version:${RESET} ${BOLD}$downloaded_version${RESET}"
    log "Downloaded version: $downloaded_version"
  fi
  
  echo
  echo -e "${YELLOW}Removing old installation (if any)...${RESET}"
  progress_bar 12 "Cleaning old installs"
  sudo rm -rf "$INSTALL_DIR" "${INSTALL_DIR}"* || true
  log "Old installation removed."

  echo -e "${YELLOW}Installing new version to ${INSTALL_DIR}...${RESET}"
  sudo mv "$TMPDIR/Discord" "$INSTALL_DIR"
  sudo chown -R root:root "$INSTALL_DIR" || true
  sudo chmod -R 755 "$INSTALL_DIR" || true
  log "Moved new Discord to $INSTALL_DIR"

  echo -e "${YELLOW}Creating launcher and symlink...${RESET}"
  sudo ln -sf "$INSTALL_DIR/Discord" /usr/bin/discord
  sudo tee "$DESKTOP_FILE" >/dev/null <<EOF
[Desktop Entry]
Name=Discord
Comment=Chat for Communities and Friends
Exec=/usr/bin/discord
Icon=$INSTALL_DIR/discord.png
Terminal=false
Type=Application
Categories=Network;Chat;
EOF
  sudo chmod 644 "$DESKTOP_FILE"
  log "Symlink and desktop file created."

  echo
  echo -e "${GREEN}${BOLD}Finalizing…${RESET}"
  progress_bar 18 "Finalizing installation"

  echo
  print_dragon
  echo -e "${GREEN}${BOLD}🎉 Discord was updated successfully!${RESET}"
  echo -e "${CYAN}Installed version:${RESET} ${BOLD}$downloaded_version${RESET}"
  echo -e "${CYAN}Run:${RESET} ${BOLD}discord${RESET} or launch from your apps menu."
  log "Update finished successfully. Version: $downloaded_version"

  cat <<'CELEB'
                 \  ^__^
                  \ (•ㅅ•)
                    /   \
                   (     )
                    `---'
CELEB

  cleanup
}

check_requirements
main
DISCORD_EOF

  sudo chmod +x "$INSTALL_DIR/modules/update-discord"
  log_success "Discord module created"
}

# -------------------------
#  VERIFY INSTALLATION
# -------------------------
verify_installation() {
  log_info "Verifying installation..."
  
  local errors=0
  
  # Check main command
  if [ ! -x "$BIN_DIR/$COMMAND_NAME" ]; then
    log_error "Main command not found or not executable"
    errors=$((errors + 1))
  fi
  
  # Check module directory
  if [ ! -d "$INSTALL_DIR/modules" ]; then
    log_error "Module directory not found"
    errors=$((errors + 1))
  fi
  
  # Check Discord module
  if [ ! -x "$INSTALL_DIR/modules/update-discord" ]; then
    log_error "Discord module not found or not executable"
    errors=$((errors + 1))
  fi
  
  if [ $errors -eq 0 ]; then
    log_success "Installation verified successfully"
    return 0
  else
    log_error "Installation verification failed with $errors error(s)"
    return 1
  fi
}

# -------------------------
#  SHOW SUCCESS MESSAGE
# -------------------------
show_success() {
  echo
  echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════╗${RESET}"
  echo -e "${GREEN}${BOLD}║                                               ║${RESET}"
  echo -e "${GREEN}${BOLD}║        ✓ Installation Complete! ✓            ║${RESET}"
  echo -e "${GREEN}${BOLD}║                                               ║${RESET}"
  echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════╝${RESET}"
  echo
  echo -e "${CYAN}${BOLD}Command installed:${RESET} $COMMAND_NAME"
  echo
  echo -e "${CYAN}${BOLD}Quick Start:${RESET}"
  echo -e "  ${YELLOW}$COMMAND_NAME -u discord${RESET}       Update Discord"
  echo -e "  ${YELLOW}$COMMAND_NAME -l${RESET}               List available packages"
  echo -e "  ${YELLOW}$COMMAND_NAME --help${RESET}           Show help"
  echo
  echo -e "${CYAN}${BOLD}Installation Details:${RESET}"
  echo -e "  Command:        $BIN_DIR/$COMMAND_NAME"
  echo -e "  Modules:        $INSTALL_DIR/modules/"
  echo -e "  Logs:           $INSTALL_DIR/logs/"
  echo
  echo -e "${CYAN}${BOLD}Next Steps:${RESET}"
  echo -e "  1. Try updating Discord: ${YELLOW}$COMMAND_NAME -u discord${RESET}"
  echo -e "  2. Add more modules to: ${YELLOW}$INSTALL_DIR/modules/${RESET}"
  echo -e "  3. Share this with friends! ⭐"
  echo
  echo -e "${GREEN}Happy updating! 🚀${RESET}"
  echo
}

# -------------------------
#  MAIN INSTALLATION
# -------------------------
main() {
  print_header
  
  echo -e "${CYAN}This installer will set up the pkgup package update system.${RESET}"
  echo -e "${CYAN}Command name: ${BOLD}$COMMAND_NAME${RESET}"
  echo
  
  # Checks
  check_root
  check_sudo
  check_dependencies
  
  echo
  log_info "Starting installation..."
  echo
  
  # Installation steps
  create_directories
  create_dispatcher
  create_discord_module
  
  echo
  
  # Verify
  if verify_installation; then
    show_success
  else
    echo
    log_error "Installation failed. Please check the errors above."
    exit 1
  fi
}

# -------------------------
#  ENTRY POINT
# -------------------------
main "$@"
