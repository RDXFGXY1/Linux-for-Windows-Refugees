# `pkgup` - A Simple, Modular Package Updater

`pkgup` is a command-line tool for updating self-contained applications that don't come from your system's main package manager (e.g., applications installed from `.tar.gz` files).

It uses a modular architecture, where each application has its own update script.

## Installation

To install `pkgup`, run the `install.sh` script:

```bash
sudo ./install.sh
```

This will install the `pkgup` command to `/usr/local/bin/pkgup` and its modules to `/usr/local/lib/pkgup/modules`.

## Uninstallation

To uninstall `pkgup`, run the `uninstall.sh` script:

```bash
sudo ./uninstall.sh
```

## Usage

### List Available Packages

To see which applications can be updated with `pkgup`, use the `-l` or `--list` flag:

```bash
pkgup -l
```

### Update a Package

To update a specific package, use the `-u` or `--update` flag, followed by the package name:

```bash
pkgup -u discord
```

## How it Works

The `pkgup` command is a simple dispatcher. When you run `pkgup -u <package>`, it looks for an executable script named `update-<package>` in the `/usr/local/lib/pkgup/modules` directory.

If it finds the script, it executes it.

## Modules

### Discord (v3.0 - Multi-distro Support)

The Discord module has been enhanced with intelligent distribution detection and multi-method installation support.

**Features:**

- Automatic Linux distribution detection (Debian, Fedora, Arch, SUSE)
- Distribution-specific installation methods using native package managers
- Fallback chain: Package Manager → Flatpak → Tarball
- Version detection across different installation methods
- Installation method tracking and logging

**Supported Installation Methods:**

| Distribution Family | Primary Method | Fallback 1 | Fallback 2 |
|-------------------|----------------|------------|------------|
| Debian/Ubuntu | `.deb` via apt | Flatpak | Tarball |
| Fedora/RHEL/CentOS | `.rpm` via dnf | Flatpak | Tarball |
| Arch/Manjaro | AUR (yay/paru) | Flatpak | Tarball |
| openSUSE/SUSE | `.rpm` via zypper | Flatpak | Tarball |
| Other/Unknown | Flatpak | Tarball | - |

**Usage:**

```bash
# Install or update Discord with automatic distribution detection
pkgup -u discord

# Skip confirmation prompts (useful for scripts/automation)
pkgup -u discord --yes
```

**Examples by Distribution:**

*Debian/Ubuntu:*

```bash
# The updater will:
# 1. Detect Debian-based system
# 2. Download Discord .deb package
# 3. Install with dpkg and fix dependencies with apt-get
pkgup -u discord
```

*Fedora/RHEL:*

```bash
# The updater will:
# 1. Detect Fedora-based system
# 2. Download Discord .rpm package
# 3. Install with dnf (or yum on older systems)
pkgup -u discord
```

*Arch/Manjaro:*

```bash
# The updater will:
# 1. Detect Arch-based system
# 2. Check for AUR helper (yay or paru)
# 3. Install from AUR with full dependency resolution
pkgup -u discord
```

*openSUSE:*

```bash
# The updater will:
# 1. Detect openSUSE-based system
# 2. Download Discord .rpm package
# 3. Install with zypper
pkgup -u discord
```

**Troubleshooting:**

- **Missing AUR helper on Arch:** If you see a warning about missing `yay` or `paru`, install one:

  ```bash
  # Install yay
  sudo pacman -S yay
  # OR install paru
  sudo pacman -S paru
  ```

- **Dependency issues on Debian:** The updater automatically runs `apt-get install -f` to fix broken dependencies after installing the .deb.

- **Flatpak fallback:** If your system doesn't have a native package manager setup, the updater will try Flatpak. Ensure `flatpak` is installed:

  ```bash
  # Debian
  sudo apt install flatpak
  # Fedora
  sudo dnf install flatpak
  # Arch
  sudo pacman -S flatpak
  # SUSE
  sudo zypper install flatpak
  ```

- **Tarball fallback:** The original tarball installation method is always available as a final fallback for maximum compatibility.

**Log Location:**

Installation logs are saved to `/var/log/update-discord.log` for debugging and reference.

## Creating New Update Modules

You can easily extend `pkgup` to update other applications. For multi-distro support, follow the pattern used in the Discord module:

1. **Create a new script** in `/usr/local/lib/pkgup/modules` with the name `update-<appname>`.

2. **Add distribution detection:**

   ```bash
   # Add at the beginning after configuration
   source /etc/os-release
   DETECTED_DISTRO=$(detect_distro)  # Use the helper function from the module
   ```

3. **Implement distribution-specific installation functions:**
   - `install_<appname>_debian()`
   - `install_<appname>_fedora()`
   - `install_<appname>_arch()`
   - `install_<appname>_suse()`
   - `install_<appname>_flatpak()` (optional, universal fallback)
   - `install_<appname>_tarball()` (final fallback)

4. **Route installation based on detected distro in your main function**

5. **Make the script executable:**

   ```bash
   sudo chmod +x /usr/local/lib/pkgup/modules/update-<appname>
   ```

Now you can run `pkgup -u <appname>` to update your application with automatic multi-distro support.
