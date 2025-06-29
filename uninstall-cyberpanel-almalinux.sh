#!/bin/bash

# Author: Ryan Johnson
# This script was created by analyzing the install script and community docs at
# https://community.cyberpanel.net and combining the two knowledge sources to produce
# a tailored answer for AlmaLinux.
# This page in particular was used as basis: https://community.cyberpanel.net/t/uninstall-cyberpanel/38453
# The `yum` commands have been updated for use with the newer `dnf` package manager.
# Gemini was used to integrate specific knowledge from the installer script and help pages
# with general knowledge of Linux environment and AlmaLinux in particular.

# Do NOT exit immediately on non-zero status. We want to complete as many steps as possible.
# Individual commands will use '|| true' or explicit error handling where appropriate.
set +e

# --- Initial Script Setup and Warnings ---
echo "#####################################################################"
echo "#               CyberPanel Uninstallation Script                    #"
echo "#####################################################################"
echo ""
echo "WARNING: This script will attempt to uninstall CyberPanel and its"
echo "associated components from your AlmaLinux system. This process is"
echo "COMPLEX and can lead to data loss or system instability if not done"
echo "carefully. It is highly recommended to have a FULL BACKUP of your"
echo "server before proceeding."
echo ""
echo "This script is designed for AlmaLinux. Running it on other operating"
echo "systems may lead to unexpected results."
echo ""

# Check for root privileges
if [[ $(id -u) -ne 0 ]]; then
    echo "ERROR: This script must be run as root. Please use 'sudo su -' or 'sudo ./uninstall_script.sh'."
    exit 1
fi

read -r -p "Do you understand the risks and wish to proceed with the uninstallation (y/N)? " CONFIRM_PROCEED
if [[ ! "$CONFIRM_PROCEED" =~ ^[Yy]$ ]]; then
    echo "Uninstallation aborted by user."
    exit 0
fi

echo ""
echo "Starting CyberPanel uninstallation process..."
echo "Skipping DNF update to focus on uninstallation tasks."
echo ""

## Helper Function for DNF Package Removal
# This function attempts to remove a package using dnf.
# It explicitly excludes kernel-related packages to prevent system breakage.
# If the dnf removal fails (e.g., due to a scriptlet error), it will explicitly
# inform the user about the issue and the potential manual steps required,
# but WILL NOT automatically force-remove packages that cause system instability.
# If the package is not found, it prints a message and skips.
remove_package_if_installed() {
    local PACKAGE_NAME=$1
    echo "Attempting to remove package: $PACKAGE_NAME"

    # Define a list of critical kernel and system packages to always exclude from removal
    local -a CRITICAL_EXCLUDE_PACKAGES=(
        "kernel"
        "kernel-core"
        "kernel-modules"
        "kernel-modules-core"
        "kernel-headers"
        "glibc" # Very fundamental C library
        "systemd" # Init system
        "dnf"     # The package manager itself
        "rpm"     # RPM Package Manager
        "bash"    # Shell
        "filesystem" # Core file system structure
    )

    # Build the --exclude string for dnf
    local EXCLUDE_FLAGS=""
    for pkg in "${CRITICAL_EXCLUDE_PACKAGES[@]}"; do
        EXCLUDE_FLAGS+=" --exclude=$pkg"
    done

    # Check if the package is actually installed or recognized by dnf/rpm before trying removal
    if ! dnf list installed "$PACKAGE_NAME" &>/dev/null && ! rpm -q "$PACKAGE_NAME" &>/dev/null; then
        echo "Package $PACKAGE_NAME is not installed or not recognized by dnf/rpm. Skipping dnf removal for this package."
        echo "" # For readability
        return 0 # Exit function successfully if not installed
    fi

    echo "Package $PACKAGE_NAME is installed. Proceeding with removal."

    # First, try dnf remove normally
    if dnf remove -y "$PACKAGE_NAME" $EXCLUDE_FLAGS; then
        echo "Successfully removed $PACKAGE_NAME via dnf."
        echo "" # For readability
        return 0 # Exit function successfully
    else
        echo "Error: dnf remove for $PACKAGE_NAME failed."
        echo "  This is likely due to a pre-uninstallation scriptlet error (e.g., exit status 127) or complex dependencies."

        # Special handling for OpenLiteSpeed, which is known to cause severe issues
        if [[ "$PACKAGE_NAME" == "openlitespeed" ]]; then
            echo "  CRITICAL PACKAGE: OpenLiteSpeed removal failed. This package is known to have problematic uninstall scriptlets."
            echo "  Automatically forcing its removal can lead to an unbootable system."
            echo "  If you are prepared for potential system repair or OS reinstallation, you may try:"
            echo "  -> sudo rpm -e --noscripts --nodeps openlitespeed"
            echo "  -> THEN re-run this script."
            echo "  This script WILL NOT automatically force-remove 'openlitespeed' due to high risk."
        else
            echo "  For this package ($PACKAGE_NAME), consider running 'dnf remove --assumeno $PACKAGE_NAME' to inspect dependencies, or 'rpm -e --noscripts --nodeps $PACKAGE_NAME' as a last resort."
            echo "  This script will continue, but ensure this package is dealt with manually if it's critical."
        fi
        echo "" # For readability
        return 1 # Indicate failure to remove package cleanly
    fi
}

## Phase 1: Stop and Disable CyberPanel Services

# Stop CyberPanel's main services (using -q to suppress "Unit not loaded" messages if service is already stopped/not found)
echo "Stopping CyberPanel-related services..."
systemctl stop lscpd.service 2>/dev/null || true
systemctl stop lsws.service 2>/dev/null || true
systemctl stop mariadb.service 2>/dev/null || true
systemctl stop pure-ftpd.service 2>/dev/null || true
systemctl stop pdns.service 2>/dev/null || true
systemctl stop memcached.service 2>/dev/null || true # If installed
systemctl stop redis.service 2>/dev/null || true # If installed
systemctl stop watchdog.service 2>/dev/null || true # If enabled
echo "Services stopped."

# Disable CyberPanel services from starting on boot (using -q to suppress messages)
echo "Disabling CyberPanel-related services from starting on boot..."
systemctl disable lscpd.service 2>/dev/null || true
systemctl disable lsws.service 2>/dev/null || true
systemctl disable mariadb.service 2>/dev/null || true
systemctl disable pure-ftpd.service 2>/dev/null || true
systemctl disable pdns.service 2>/dev/null || true
systemctl disable memcached.service 2>/dev/null || true
systemctl disable redis.service 2>/dev/null || true
systemctl disable watchdog.service 2>/dev/null || true
echo "Services disabled."

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload
echo "Systemd daemon reloaded."
echo ""

## Phase 2: Remove CyberPanel Directories and Files (Manual Cleanup - for files/dirs DNF doesn't manage)

echo "Removing CyberPanel directories and loose files..."

# Remove CyberPanel's main installation directory and virtual environment:
echo "Removing /usr/local/CyberCP and /usr/local/cyberpanel..."
rm -rf /usr/local/CyberCP || true
rm -rf /usr/local/cyberpanel || true

# Remove LiteSpeed/OpenLiteSpeed web server files
echo "Removing /usr/local/lsws and /usr/local/lscp..."
rm -rf /usr/local/lsws || true
rm -rf /usr/local/lscp || true # If present

# Remove CyberPanel configuration files:
echo "Removing /etc/cyberpanel..."
rm -rf /etc/cyberpanel || true

# Remove Python pip configuration (if only used by CyberPanel)
# Check for /root/.pip existence before attempting to remove.
echo "Checking and removing /root/.pip if it contains CyberPanel-specific configuration..."
if [ -d /root/.pip ]; then
    # Add a more robust check here if you suspect other apps use pip.
    # For now, assuming if it's there after CP install, it's mostly CP related for simplicity.
    if grep -q "cyberpanel.sh" /root/.pip/pip.conf 2>/dev/null; then
        echo "  /root/.pip/pip.conf found with CyberPanel specific mirror. Removing /root/.pip"
        rm -rf /root/.pip || true
    else
        echo "  /root/.pip exists but doesn't seem CyberPanel-specific. Skipping removal to avoid breaking other tools."
    fi
else
    echo "  /root/.pip not found. Skipping."
fi


# Remove `acme.sh` directory (if not used for other SSL certs)
echo "Checking and removing /root/.acme.sh if not used by other services..."
if [ -d /root/.acme.sh ]; then
    # This is a critical component for SSL. Only remove if SURE it's not used elsewhere.
    # For a dedicated CyberPanel server, it's usually safe. For shared, be careful.
    read -r -p "Is /root/.acme.sh used exclusively by CyberPanel for SSL certificates (y/N)? " CONFIRM_ACME
    if [[ "$CONFIRM_ACME" =~ ^[Yy]$ ]]; then
        echo "  Removing /root/.acme.sh..."
        rm -rf /root/.acme.sh || true
    else
        echo "  Skipping removal of /root/.acme.sh as per user's choice."
    fi
else
    echo "  /root/.acme.sh not found. Skipping."
fi


# Remove temporary files from `/root/`
echo "Removing temporary files from /root/ and /usr/local/..."
rm -f /root/cyberpanel.sh || true
if [ -f /usr/local/requirments.txt ]; then
    echo "  /usr/local/requirments.txt found. Removing."
    rm -f /usr/local/requirments.txt || true
elif [ -f /usr/local/requirements.txt ]; then
    echo "  /usr/local/requirements.txt found (assuming typo fixed). Removing."
    rm -f /usr/local/requirements.txt || true
else
    echo "  Neither /usr/local/requirments.txt nor /usr/local/requirements.txt found. Skipping."
fi
rm -f /root/php_session_script.sh || true # If present
rm -rf /root/cyberpanel-tmp || true # Temporary directory for LSWS license check

# Remove utility scripts and profile changes
echo "Removing utility scripts and profile changes..."
rm -f /usr/bin/adminPass || true
rm -f /usr/bin/cyberpanel_utility || true
rm -f /etc/profile.d/cyberpanel.sh || true

# Remove DKIM directory (Domain Keys Identity Management---for preventing email spoofing)
# Note: While this directory is removed, the package itself should be handled by dnf below.
echo "Removing /etc/opendkim directory..."
rm -rf /etc/opendkim || true
echo "Manual file and directory cleanup complete."
echo ""

## Phase 3: Uninstall Packages Installed by CyberPanel (using DNF for consistency)

echo "Removing core CyberPanel packages via DNF..."

# LiteSpeed PHP (lsphp) versions
# CyberPanel installs various lsphpXX packages. We'll try to remove all of them.
# Removing lsphp* before openlitespeed as lsphp depends on openlitespeed
remove_package_if_installed "lsphp*"

# OpenLiteSpeed Web Server - This is handled very cautiously due to past issues
remove_package_if_installed "openlitespeed"
remove_package_if_installed "openlitespeed-extra" # Extra packages for OLS

# MariaDB/MySQL Database
remove_package_if_installed "mariadb-server"
remove_package_if_installed "mariadb"
remove_package_if_installed "mariadb-common"

# Pure-FTPd
remove_package_if_installed "pure-ftpd"

# PowerDNS
remove_package_if_installed "pdns-server"
remove_package_if_installed "pdns-backend-mysql" # Common backend, might vary

# Memcached (service and PHP extension)
remove_package_if_installed "memcached"
remove_package_if_installed "lsphp*-memcached"
remove_package_if_installed "lsphp*-pecl-memcached" # Specific PECL module
remove_package_if_installed "lsmcd" # LiteSpeed Memcached Daemon

# Redis (service and PHP extension)
remove_package_if_installed "redis"
remove_package_if_installed "lsphp*-redis"

# OpenDKIM (as discussed, prefer dnf if it's a package)
remove_package_if_installed "opendkim"

# Firewalld (already handled by user in previous steps, but including for completeness)
# The script intentionally comments out firewalld removal as it's a core OS component
# and was previously addressed. Uncomment and use with extreme caution if needed.
# if dnf list installed firewalld &>/dev/null; then
#     echo "Firewalld is installed. Attempting to remove..."
#     remove_package_if_installed "firewalld"
# else
#     echo "Firewalld package not found. Skipping."
# fi

# Optional: Remove specific Python packages installed by CyberPanel's venv (if not part of system python)
# The virtual environment is removed in Phase 2, so these should be handled.
# If you suspect system-wide Python installations were affected or are now orphaned:
# remove_package_if_installed "python36u" # Specific to CentOS 7
# remove_package_if_installed "python36u-pip" # Specific to CentOS 7
# remove_package_if_installed "python36u-devel" # Specific to CentOS 7
# remove_package_if_installed "platform-python-devel" # Specific to CentOS 8
# remove_package_if_installed "python3-devel" # For openEuler/Ubuntu, etc.

# Remove any remaining orphaned dependencies, explicitly excluding kernel-related packages
echo "Running dnf autoremove to clean up orphaned dependencies..."
dnf autoremove -y --exclude=kernel* --exclude=glibc --exclude=systemd --exclude=dnf --exclude=rpm --exclude=bash --exclude=filesystem || true
echo "DNF package cleanup complete."
echo ""

## Phase 4: Revert System Configuration Changes

echo "Reverting system configuration changes made by CyberPanel..."

# Revert SELinux to enforcing (if desired and it was permissive before)
# The script sets SELINUX=permissive, change back to enforcing if that was your original state
echo "Checking SELinux configuration..."
if grep -q "SELINUX=permissive" /etc/selinux/config; then
    read -r -p "SELinux was set to 'permissive'. Do you want to set it back to 'enforcing' (y/N)? " CONFIRM_SELINUX
    if [[ "$CONFIRM_SELINUX" =~ ^[Yy]$ ]]; then
        sed -i 's/SELINUX=permissive/SELINUX=enforcing/g' /etc/selinux/config
        echo "SELinux set to 'enforcing'. A reboot is recommended for full effect."
    else
        echo "SELinux setting retained as 'permissive'."
    fi
else
    echo "SELinux configuration not changed from 'enforcing' by CyberPanel, or already 'disabled'."
fi

# Revert /etc/hosts changes:
echo "Reviewing and potentially reverting /etc/hosts changes..."
# The script adds `127.0.0.1 <hostname>` and potentially Tencent/Alibaba mirrors.
# Manual inspection is safest as automatic removal can be risky if lines were modified.
echo "Please manually inspect /etc/hosts for CyberPanel-related entries (e.g., your hostname on 127.0.0.1, or cloud provider mirrors) and remove if appropriate."
echo "Original /etc/hosts before any changes by CP is usually lean. Compare if you have a backup."
echo "Current /etc/hosts:"
cat /etc/hosts
echo ""

# Revert rc.local changes:
echo "Reverting /etc/rc.d/rc.local or /etc/rc.local changes..."
# The script adds `echo 1000000 > /proc/sys/kernel/pid_max` and `echo 1 > /sys/kernel/mm/ksm/run` and watchdog commands.
# It also ensures it's executable.
if [ -f /etc/rc.d/rc.local ]; then
    sed -i '/echo 1000000 > \/proc\/sys\/kernel\/pid_max/d' /etc/rc.d/rc.local || true
    sed -i '/echo 1 > \/sys\/kernel\/mm\/ksm\/run/d' /etc/rc.d/rc.local || true
    sed -i '/nohup watchdog lsws > \/dev\/null 2>\&1/d' /etc/rc.d/rc.local || true
    sed -i '/nohup watchdog mariadb > \/dev\/null 2>\&1/d' /etc/rc.d/rc.local || true
    # Remove any blank lines that might result from above deletions
    sed -i '/^$/d' /etc/rc.d/rc.local || true
    echo "Cleaned /etc/rc.d/rc.local."
fi
if [ -f /etc/rc.local ]; then # For Ubuntu/Debian based systems primarily
    sed -i '/echo 1000000 > \/proc\/sys\/kernel\/pid_max/d' /etc/rc.local || true
    sed -i '/echo 1 > \/sys\/kernel\/mm\/ksm\/run/d' /etc/rc.local || true
    sed -i '/nohup watchdog lsws > \/dev\/null 2>\&1/d' /etc/rc.local || true
    sed -i '/nohup watchdog mariadb > \/dev\/null 2>\&1/d' /etc/rc.local || true
    sed -i '/^$/d' /etc/rc.local || true
    echo "Cleaned /etc/rc.local."
fi
systemctl disable rc-local.service 2>/dev/null || true # Disable if it was enabled by CP
echo ""

# Revert sysctl.conf changes:
echo "Reverting /etc/sysctl.conf changes..."
# Remove or comment out lines like: nf_conntrack_max, fs.file-max
sed -i '/net.netfilter.nf_conntrack_max=/d' /etc/sysctl.conf || true
sed -i '/net.nf_conntrack_max=/d' /etc/sysctl.conf || true
sed -i '/fs.file-max = 65535/d' /etc/sysctl.conf || true
sysctl -p # Apply changes
echo "sysctl.conf reverted. Run 'sysctl -p' manually if needed."
echo ""

# Revert limits.conf changes:
echo "Reverting /etc/security/limits.conf changes..."
# Remove the blocks added by CyberPanel for nofile and nproc limits
sed -i '/\* soft    nofile          65535/d' /etc/security/limits.conf || true
sed -i '/\* hard    nofile          65535/d' /etc/security/limits.conf || true
sed -i '/root             soft    nofile          65535/d' /etc/security/limits.conf || true
sed -i '/root             hard    nofile          65535/d' /etc/security/limits.conf || true
sed -i '/\* soft    nproc           65535/d' /etc/security/limits.conf || true
sed -i '/\* hard    nproc           65535/d' /etc/security/limits.conf || true
sed -i '/root             soft    nproc           65535/d' /etc/security/limits.conf || true
sed -i '/root             hard    nproc           65535/d' /etc/security/limits.conf || true
echo "limits.conf reverted."
echo ""

# Revert resolv.conf and systemd-resolved changes:
echo "Reverting resolv.conf and systemd-resolved changes..."
if [ -f /etc/resolv.conf_bak ]; then
    echo "Restoring original /etc/resolv.conf from backup..."
    rm -f /etc/resolv.conf || true
    mv /etc/resolv.conf_bak /etc/resolv.conf || true
else
    echo "No /etc/resolv.conf_bak found. Manual check of /etc/resolv.conf recommended."
    echo "Current /etc/resolv.conf:"
    cat /etc/resolv.conf
fi

echo "Checking and potentially re-enabling systemd-resolved..."
# Check if systemd-resolved.service unit file actually exists before trying to manage it
if [ -f /usr/lib/systemd/system/systemd-resolved.service ] || [ -f /etc/systemd/system/systemd-resolved.service ]; then
    if systemctl is-enabled systemd-resolved.service &>/dev/null; then
        echo "systemd-resolved is already enabled."
    elif systemctl is-masked systemd-resolved.service &>/dev/null; then
        echo "systemd-resolved is masked. Unmasking, enabling, and starting."
        systemctl unmask systemd-resolved.service || true
        systemctl enable systemd-resolved.service || true
        systemctl start systemd-resolved.service || true
    else
        echo "systemd-resolved is not enabled or masked. Enabling and starting."
        systemctl enable systemd-resolved.service || true
        systemctl start systemd-resolved.service || true
    fi
else
    echo "systemd-resolved.service unit file not found. Skipping re-enabling/starting of systemd-resolved."
    echo "If you manually installed systemd-resolved and it's not starting, please check its installation."
fi
systemctl restart systemd-networkd 2>/dev/null || true
echo "resolv.conf and systemd-resolved changes processed."
echo ""

# Remove CyberPanel's added DNF/YUM repositories:
echo "Cleaning up CyberPanel's DNF/YUM repositories..."
# List common repo files added by CyberPanel
declare -a CP_REPOS=(
    "MariaDB.repo"
    "litespeed.repo"
    "powerdns-auth-43.repo"
    "epel-release.repo"
    "remi-release.repo"
    "gf.repo"
    "ius.repo"
    "lux-release-*.repo" # Use wildcard as name might vary slightly
    "_copr_copart-restic.repo"
)

for repo_file in "${CP_REPOS[@]}"; do
    if [ -f "/etc/yum.repos.d/$repo_file" ]; then
        echo "  Removing /etc/yum.repos.d/$repo_file..."
        rm -f "/etc/yum.repos.d/$repo_file" || true
    elif ls "/etc/yum.repos.d/$repo_file" 1>/dev/null 2>&1; then # Check for wildcards
        echo "  Removing /etc/yum.repos.d/$repo_file (with wildcard match)..."
        rm -f "/etc/yum.repos.d/$repo_file" || true
    else
        echo "  /etc/yum.repos.d/$repo_file not found. Skipping."
    fi
done
echo "Repository cleanup complete."
echo ""

## Phase 5: Restore Other Services (if applicable)

echo "Checking and potentially restoring services that CyberPanel might have stopped/masked..."

# The cyberpanel.sh script stops and masks httpd, apache2, named, and exim.
# Unmask and enable (if needed), then start services.

# HTTPD / Apache2
if systemctl is-masked httpd.service &>/dev/null; then
    echo "httpd service is masked. Unmasking, enabling, and starting."
    systemctl unmask httpd.service || true
    systemctl enable httpd.service || true
    systemctl start httpd.service || true
elif systemctl is-masked apache2.service &>/dev/null; then
    echo "apache2 service is masked. Unmasking, enabling, and starting."
    systemctl unmask apache2.service || true
    systemctl enable apache2.service || true
    systemctl start apache2.service || true
else
    echo "Neither httpd nor apache2 service appears masked by CyberPanel. No action taken."
fi

# Named (DNS service)
if systemctl is-masked named.service &>/dev/null; then
    echo "named service is masked. Unmasking, enabling, and starting."
    systemctl unmask named.service || true
    systemctl enable named.service || true
    systemctl start named.service || true
else
    echo "named service does not appear masked by CyberPanel. No action taken."
fi

# Exim (Mail Transfer Agent)
if systemctl is-masked exim.service &>/dev/null; then
    echo "exim service is masked. Unmasking, enabling, and starting."
    systemctl unmask exim.service || true
    systemctl enable exim.service || true
    systemctl start exim.service || true
else
    echo "exim service does not appear masked by CyberPanel. No action taken."
fi
echo "Service restoration attempts complete."
echo ""

## Phase 6: Final Cleanup and Verification

echo "Performing final cleanup and verification steps..."

# Clean DNF cache:
echo "Cleaning DNF cache..."
dnf clean all
echo "DNF cache cleaned."

# Remove any remaining symlinks created by CyberPanel:
echo "Removing CyberPanel-related symlinks..."
if [ -L /usr/bin/pip ]; then
    echo "  /usr/bin/pip is a symlink. Removing."
    rm -f /usr/bin/pip || true
fi
# The script links /usr/bin/pip3.6 to /usr/bin/pip and /usr/bin/pip3 to /usr/bin/pip3.6 on Ubuntu 20
# And /usr/bin/pip3 to /usr/bin/pip on CentOS/openEuler
# If your system relies on these symlinks for other Python installations, DO NOT run this.
# Consider manually checking: 'ls -l /usr/bin/pip*', 'ls -l /usr/bin/php'
# For safety, these specific Python symlink removals are commented out.
# if [ -L /usr/bin/pip3.6 ]; then rm -f /usr/bin/pip3.6; fi
# if [ -L /usr/bin/pip3 ]; then rm -f /usr/bin/pip3; fi


if [ -L /usr/bin/php ]; then
    echo "  /usr/bin/php is a symlink. Removing."
    rm -f /usr/bin/php || true
fi
if [ -L /usr/local/bin/watchdog ]; then
    echo "  /usr/local/bin/watchdog is a symlink. Removing."
    rm -f /usr/local/bin/watchdog || true
fi
echo "Symlink cleanup complete."

# Check cron jobs for root:
echo "Checking root's cron jobs for CyberPanel entries..."
CRONTAB_CLEANED="false"
if crontab -l 2>/dev/null | grep -q "cyberpanel"; then
    echo "  CyberPanel entries found in root's crontab. Removing them."
    (crontab -l | grep -v "cyberpanel") | crontab - || true
    CRONTAB_CLEANED="true"
elif crontab -l 2>/dev/null | grep -q "lswsctrl restart"; then # Also common for OLS watchdog
    echo "  OpenLiteSpeed restart entry found in root's crontab. Removing it."
    (crontab -l | grep -v "lswsctrl restart") | crontab - || true
    CRONTAB_CLEANED="true"
fi

if [ "$CRONTAB_CLEANED" = "true" ]; then
    echo "  Root's crontab cleaned. You can run 'crontab -l' to verify."
else
    echo "  No obvious CyberPanel-related entries found in root's crontab."
fi
echo "Cron job cleanup complete."

# Review user accounts (manual check recommended):
echo "Review user accounts that might have been created by CyberPanel (e.g., 'cyberpanel', 'lsadm', 'pure-ftpd')."
echo "Run 'cat /etc/passwd' and 'cat /etc/group' to inspect. Only remove if SURE they are not needed by other services."
echo "Example commands (use with extreme caution if not a dedicated server):"
echo "  userdel cyberpanel"
echo "  groupdel cyberpanel"
echo "  userdel lsadm" # Often related to LiteSpeed
echo "  groupdel lsadm"

# Final reboot recommendation
echo ""
echo "#####################################################"
echo "  CyberPanel uninstallation script has completed.    "
echo "  It is HIGHLY RECOMMENDED to REBOOT your server     "
    echo "  now to ensure all changes take full effect.        "
echo "#####################################################"
read -r -p "Would you like to reboot your server now (y/N)? " REBOOT_CONFIRM
if [[ "$REBOOT_CONFIRM" =~ ^[Yy]$ ]]; then
    reboot
else
    echo "Reboot skipped. Please remember to reboot your server soon."
fi
