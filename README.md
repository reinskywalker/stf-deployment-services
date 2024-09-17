Here is the `README` content without markdown formatting:

# STF Deployment Services

This repository contains a set of modular PowerShell scripts designed to automate the deployment of Smartphone Test Farm (STF) services using Docker on a Windows environment. Each script serves a specific purpose, making it easy to maintain, update, and reuse.

Directory Structure:

deploy_stf/
- modules/
  - Install-Chocolatey.ps1
  - Install-Tool.ps1
  - Prepare-Environment.ps1
  - Run-Docker-Container.ps1
- deploy_stf.ps1

- deploy_stf.ps1: The main script that orchestrates the entire deployment process.
- modules/: A folder containing all the helper scripts used by deploy_stf.ps1 for different tasks.

Modules:

1. Install-Chocolatey.ps1
   This script checks if Chocolatey is installed on the system. If not, it installs Chocolatey, a package manager for Windows that helps in managing dependencies and installations.
   Functions:
   - Install-Chocolatey: Installs Chocolatey if not present, with proper error handling.

2. Install-Tool.ps1
   This script provides a function to check for and install various tools needed for STF deployment using Chocolatey.
   Functions:
   - Install-Tool: Takes the tool name and its Chocolatey package name as parameters and installs the tool if it's not already present on the system.

3. Prepare-Environment.ps1
   This script prepares the environment for STF deployment by installing necessary tools, starting Docker Desktop if it is not running, and pulling required Docker images.
   Functions:
   - Prepare-Environment: Prepares the system environment, installs required tools (ADB, Docker Desktop), starts Docker Desktop, and pulls necessary Docker images.

4. Run-Docker-Container.ps1
   This script provides a function to manage Docker containers needed for STF deployment. It removes any existing containers and starts new ones with specified configurations.
   Functions:
   - Run-Docker-Container: Takes the container name and Docker command as parameters, removes existing containers, and starts new ones.

Main Script:

deploy_stf.ps1
This is the main script that orchestrates the STF deployment using the modular scripts located in the modules folder.
Key Features:
- Accepts --ip and --dns parameters to set up the environment variables for STF deployment.
- Imports and executes functions from the modular scripts to install tools, prepare the environment, and manage Docker containers.
- Manages the deployment lifecycle from start to finish.

Usage:

Run the main script from an elevated PowerShell session (Run as Administrator):

cd deploy_stf
.\deploy_stf.ps1 --ip=192.168.18.27 --dns=192.168.18.1

Parameters:
- --ip: The IP address for the STF deployment. Defaults to 192.168.18.27 if not provided.
- --dns: The DNS address for the STF deployment. Defaults to 192.168.18.1 if not provided.

How to Run the Scripts:

1. Clone the repository to your local machine.
   git clone https://github.com/reinskywalker/stf-deployment-services.git
   cd stf-deployment-services

2. Open PowerShell with Administrator privileges.

3. Navigate to the deploy_stf directory.

4. Run the main script with the desired parameters.

5. Follow the on-screen instructions and logs to ensure a successful deployment.

Benefits of This Modular Approach:

1. Reusability: Each script is modular and can be reused across different projects.
2. Maintainability: Update or fix a script independently without affecting others.
3. Readability: Smaller, well-organized scripts are easier to understand and manage.

Troubleshooting:

- If there are issues with installing Chocolatey or any tools, ensure that PowerShell is running with administrative privileges.
- For Docker-related issues, verify that Docker Desktop is installed and running properly. Restart Docker Desktop if necessary.
- Check the logs in C:\ProgramData\chocolatey\logs\chocolatey.log for more details on Chocolatey installation errors.

Contributing:

Contributions are welcome! If you'd like to add new features or fix bugs, feel free to open a pull request. Please ensure that your code follows the repository's structure and coding standards.

License:

This project is licensed under the MIT License - see the LICENSE file for details.