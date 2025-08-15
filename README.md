# My OpenTofu homelab infrastructure

This project uses [OpenTofu](https://opentofu.org/) to manage the infrastructure.

## Overview

This OpenTofu configuration manages various self-hosted services primarily as Docker/Podman containers. The goals are:

* **Reproducibility:** Easily set up or replicate the homelab environment.
* **Version Control:** Track all infrastructure changes using Git.
* **Automation:** Automate the provisioning and management of services.
* **Modularity:** Organize infrastructure into reusable and understandable components.

## Prerequisites

Before you begin, ensure you have the following installed and configured:

* **OpenTofu:** Version `1.6.0` or higher. [Installation Guide](https://opentofu.org/docs/intro/install/)
* **Git:** For version control.
* **Docker/Podman:** to host containers.

## Project Structure

The project is organized as follows:

```
homelab/
├── .gitignore                # Files and directories to ignore
├── README.md                 # This file
├── main.tf                   # Root module: orchestrates module calls
├── variables.tf              # Root module: global input variables
├── outputs.tf                # Root module: global outputs
├── providers.tf              # Root module: provider configurations
├── modules/                  # Local modules for different components
├───┐
│   ├── 00-globals/           # Optional: Global data sources/locals
│   ├── 01-networking/
│   │   ├── docker-network/
│   ├── 10-generic/
│   │   └── docker-service/   # Generic module for deploying Docker containers
│   └── 20-services-entertainment/     # Application-specific wrapper modules
│       ├── jellyfin/
│       └── ...               # Other application modules
│
└── services/                 # Application services (Docker containers)
```

## Configuration

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/BlackChaosNL/homelab.git
    cd homelab
    ```

2.  **Create a `.env` file:**
    Copy all `.env.example`s to `.env`:
    ```bash
    cp .env.example .env
    ```
    **Edit `.env` to set your specific values.** This file is included in `.gitignore` by default as it's expected to contain secrets. They exist in 

## Usage

Make sure you are in the root directory of the project (`homelab/`).

1.  **Initialize OpenTofu:**
    This downloads the necessary provider plugins. Run this once when you first set up the project or when you add/change providers or modules.
    ```bash
    tofu init
    ```

2.  **Plan Changes:**
    This command shows you what OpenTofu will do to reach the desired state defined in your configuration files. Review the plan carefully.
    ```bash
    tofu plan
    ```

3.  **Apply Changes:**
    This command applies the changes outlined in the plan. You will be prompted for confirmation.
    ```bash
    tofu apply
    ```

4.  **View Outputs:**
    If you have defined outputs in `outputs.tf` or in your modules, you can view them:
    ```bash
    tofu output
    ```

5.  **Destroy Infrastructure (Use with Extreme Caution!):**
    This command will attempt to destroy all resources managed by this OpenTofu configuration.
    ```bash
    tofu destroy
    ```
