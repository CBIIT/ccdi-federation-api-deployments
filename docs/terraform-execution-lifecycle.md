# Running the Terraform Execution Lifecycle
This document provides an overview of the Terraform execution lifecycle and the commands used to manage Terraform resources.

## Selecting or Creating Workspaces
Workspaces are used to manage multiple configurations in a single directory.
Selecting and/or creating a new workspace can be performed by running a single 
command: `terraform workspace select -or-create <workspace-name>`, where 
`<workspace-name>` is the name of the workspace to select or create.
Provide the name of the workspace in place of `<workspace-name>` 
(i.e., `dev`, `qa`, `stage`, or `prod`).

``` bash
terraform workspace select -or-create <workspace-name>
```

## Initializing Terraform
The `terraform init` command is used to initialize a working directory containing 
Terraform configuration files.This command downloads and installs the provider 
plugins and modules required for the configuration. Because we use remote 
backends, we must provide the `reconfigure` and `backend-config` flags to the 
`terraform init` command. Replace `<path/file>` with the path to the backend 
configuration file (i.e., `workspace/nonprod.tfbackend`)

``` bash
terraform init -reconfigure -backend-config=<path/file>
```

## Planning Terraform Changes
The `terraform plan` command is used to create an execution plan. This plan
shows what actions Terraform will take to change the infrastructure to match the
configuration. The `terraform plan` command must be run after the `terraform init`
command and before the `terraform apply` command. Replace `<path/file>` with the
path to the variable file (i.e., `workspace/dev.tfvars`).

``` bash
terraform plan -var-file=<path/file>
```

## Applying Terraform Changes
The `terraform apply` command is used to apply the changes required to reach the
desired state of the configuration. The `terraform apply` command must be run after
the `terraform plan` command. Replace `<path/file>` with the path to the variable
file (i.e., `workspace/dev.tfvars`).

``` bash
terraform apply -var-file=<path/file>
```

When prompted, type `yes` to confirm the changes.