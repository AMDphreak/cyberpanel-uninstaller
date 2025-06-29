# CyberPanel Uninstallation Script for AlmaLinux

This document provides instructions for safely downloading and executing a script designed to uninstall CyberPanel and its associated components from an AlmaLinux server.

*SECURITY ADVICE AND CORRECTNESS DISCLAIMER:* Running shell scripts, especially those that modify system configurations or remove software, requires a high level of trust and caution. This script interacts with core system components and performs irreversible actions. I am not affiliated with CyberPanel and do not monitor their progress. Consult an official representative from the organization to verify correctness of this script.

- Review Before Running: Make a reasonable attempt to review the contents of the script before executing it on your server.
- Backup Your Data: Before attempting uninstallation, ensure you have a complete and verified backup of all your data and server configuration. This helps with disaster recovery for those of you who are in high-stakes environments.
- Understand Each Step: Familiarize yourself with each command and action the script performs. If you are unsure about any part, please seek assistance from an experienced system administrator.
- Dedicated Server Recommended: For critical production environments, a full operating system reinstallation is often the most secure and cleanest way to remove complex control panels. This script is provided as a detailed manual alternative.

## How to Download and Run the Script

Follow these steps carefully to use the uninstallation script:

1. Download the Script:
   Connect to your AlmaLinux server via SSH as a user with sudo privileges. Then, use curl to download the script directly from the GitHub repository.

   ```sh
   # Ensure curl is installed (usually present, but good to confirm)
   sudo dnf install curl -y
   
   # Download the uninstallation script to your current directory
   curl -o uninstall-cyberpanel.sh https://raw.githubusercontent.com/amdphreak/cyberpanel-uninstaller/main/uninstall-cyberpanel-almalinux.sh
   ```

2. Make the Script Executable:
   Before you can run the script, you need to give it execute permissions. Ensure you are in the directory where you downloaded uninstall_cyberpanel.sh.

   ```sh
   chmod +x uninstall_cyberpanel.sh
   ```

3. Review the Script (Highly Recommended): Before executing, take a moment to review the script's contents directly on your server. This verifies the script's integrity and ensures you understand its actions. Use `less` viewer or `nano` editor (if you can install it).

   ```sh
   less uninstall_cyberpanel.sh
   ```

4. Run the Script:
   Execute the script using sudo su - to ensure it runs with proper root privileges and a clean environment.

   ```sh
   sudo su - # This command gives you a root shell. Be cautious.
   ./uninstall_cyberpanel.sh
   ```

   The script will guide you through prompts, especially for sensitive operations like .acme.sh removal or SELinux changes. Read each prompt carefully before confirming.

5. Monitor the Output:
   Pay close attention to the script's output. It will provide messages about which services are being stopped, which files are being removed, and any potential errors encountered.

6. Reboot Your Server:
   The script will ask you to reboot your server at the end. It is highly recommended to agree to the reboot to ensure all changes take full effect and any lingering processes are terminated.

   If you choose not to reboot immediately, remember to do so at your earliest convenience to complete the uninstallation process effectively.

*Disclaimer*: This script is provided "as is" without warranty of any kind. Use it at your own risk. The author (amdphreak) and Gemini are not responsible for any damage or data loss that may occur from its use.
