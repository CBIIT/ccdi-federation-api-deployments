# Installing Terraform on CloudShell 
This document provides instructions on how to install Terraform on CloudShell.

## Creating the Install Script
CloudShell will not preserve the installation of third-party packages between sessions. Therefore, we need to install terraform with each new CloudShell session. To do this, we will create a script that installs Terraform and run it each time we start a new CloudShell session.

1. Create a directory to store the script and Terraform binary.

``` bash 
mkdir -p intall && cd install
```

2. Create a script file named `install-terraform.sh` and add the following content.

``` bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```

3. Make the script executable.

``` bash
chmod +x install-terraform.sh
```

## Running the Install Script
To install Terraform on CloudShell, run the script each time you start a new CloudShell session.

1. Open a new CloudShell session.
2. Run the script.

``` bash
cd install && ./install-terraform.sh
```

3. Verify the installation.

``` bash
terraform --version
```
