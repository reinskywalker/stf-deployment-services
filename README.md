## STF Deployment Services (with Docker Compose Integration)

This repository contains a set of modular PowerShell scripts designed to automate the deployment of Smartphone Test Farm (STF) services using Docker on a Windows environment. Each script serves a specific purpose, making it easy to maintain, update, and reuse.

**Additionally, this project now supports deployment using Docker Compose, offering a simpler workflow.**

## Directory Structure

```
deploy_stf/
├── config/
│   └── nginx.conf.template
├── modules/
│   ├── Install-Chocolatey.ps1
│   ├── Install-Tool.ps1
│   ├── Prepare-Environment.ps1
│   └── Run-Docker-Container.ps1
├── nginx/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── nginx.conf
├── storage-temp/
│   ├── Dockerfile
├── deploy_stf.ps1
└── docker-compose.yml
```

**Changes:**

- `docker-compose.yml` (New): This file defines the Docker services and configurations for your STF deployment.

## Existing Features

The core functionalities described previously for `deploy_stf.ps1` and its helper scripts remain the same.

## Using Docker Compose (Recommended)

**Prerequisites:**

- Docker installed on your system.

**Steps:**

1. Clone the repository and navigate to the `deploy_stf` directory.
2. Set up the environment variables required by your STF services (refer to the `docker-compose.yml` file for details). You can do this by creating a `.env` file in the project root directory and defining variables there.
3. Run the following command to start the STF deployment using Docker Compose:

```
docker-compose up -d
```

This command will build and start the Docker containers defined in `docker-compose.yml`, automating the deployment process.

**Benefits:**

- Simplified workflow with a single command for deployment.
- Manages dependencies and configurations through `docker-compose.yml`.
- Portable deployment across environments with Docker.

## Using the Main Script (Optional)

The `deploy_stf.ps1` script is still available for advanced configurations or customization. Refer to the existing instructions and parameters for detailed usage.