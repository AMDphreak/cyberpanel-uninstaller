<a id="readme-top"></a>
<div align="center">
  <a href="https://github.com/AMDphreak/cyberpanel-uninstaller/graphs/contributors"><img src="https://img.shields.io/github/contributors/AMDphreak/cyberpanel-uninstaller.svg?style=for-the-badge" alt="Contributors"></a>
  <a href="https://github.com/AMDphreak/cyberpanel-uninstaller/network/members"><img src="https://img.shields.io/github/forks/AMDphreak/cyberpanel-uninstaller.svg?style=for-the-badge" alt="Forks"></a>
  <a href="https://github.com/AMDphreak/cyberpanel-uninstaller/stargazers"><img src="https://img.shields.io/github/stars/AMDphreak/cyberpanel-uninstaller.svg?style=for-the-badge" alt="Stargazers"></a>
  <a href="https://github.com/AMDphreak/cyberpanel-uninstaller/issues"><img src="https://img.shields.io/github/issues/AMDphreak/cyberpanel-uninstaller.svg?style=for-the-badge" alt="Issues"></a>
  <h1>CyberPanel Uninstaller</h1>
  <p>Unofficial uninstaller for CyberPanel on AlmaLinux — the company never shipped one.</p>
  <p>
    <a href="https://github.com/AMDphreak/cyberpanel-uninstaller/issues">Report Bug</a>
    &middot;
    <a href="https://github.com/AMDphreak/cyberpanel-uninstaller/issues">Request Feature</a>
  </p>

</div>


<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#installation">Installation</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

## About The Project

This document provides instructions for safely downloading and executing a script designed to uninstall CyberPanel and its associated components from an AlmaLinux server.

*SECURITY ADVICE AND CORRECTNESS DISCLAIMER:* Running shell scripts, especially those that modify system configurations or remove software, requires a high level of trust and caution. This script interacts with core system components and performs irreversible actions. I am not affiliated with CyberPanel and do not monitor their progress. Consult an official representative from the organization to verify correctness of this script.

- Review Before Running: Make a reasonable attempt to review the contents of the script before executing it on your server.
- Backup Your Data: Before attempting uninstallation, ensure you have a complete and verified backup of all your data and server configuration. This helps with disaster recovery for those of you who are in high-stakes environments.
- Understand Each Step: Familiarize yourself with each command and action the script performs. If you are unsure about any part, please seek assistance from an experienced system administrator.
- Dedicated Server Recommended: For critical production environments, a full operating system reinstallation is often the most secure and cleanest way to remove complex control panels. This script is provided as a detailed manual alternative.

## Installation

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

## Usage

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

## Contact

Ryan Johnson — [@amdphreak](https://twitter.com/amdphreak)

Project Link: https://github.com/AMDphreak/cyberpanel-uninstaller

Site: https://ryanjohnson.dev

<p align="right">(<a href="#readme-top">back to top</a>)</p>

