# Resource creation using Terraform in GCP

This Terraform project manages the infrastructure on Google Cloud Platform (GCP). It includes configurations for creating a Virtual Private Clouds (VPC), two subnets within this VPC, and a custom route, with the flexibility to use the same terraform configuration files in the same GCP project and region to create multiple VPCs including all of its resources.

## Prerequisites

- **Google Cloud Account**: Ensure you have access to a Google Cloud account.
- **Terraform Installed**: You need Terraform v0.12+ installed on your machine. [Download Terraform](https://www.terraform.io/downloads.html)
- **GCP Credentials**: Run below commands to authenticate Google cloud credentials
  ```bash
  gcloud auth login
  gcloud auth application-default login
  gcloud config set project <project_id>
  ```
- **Enabling Compute Engine API**: Before deploying your infrastructure, make sure the Compute Engine API is enabled for your GCP project. This can be done through the GCP Console or using the gcloud CLI:
  ```bash
  gcloud services enable compute.googleapis.com
  ```
## Project Structure

- `main.tf`: Contains the main set of Terraform configurations for the project.
- `vars.tf`: Defines variables used across the configurations.
- `terraform.tfvars`: Specifies values for the defined variables (should not be pushed to repo).
- `README.md`: This documentation file.

## Configuration

### Variables

- **`project_id`**: Your GCP project ID.
- **`region`**: The GCP region where your resources will be created.
- **`vpc_name`**: The name of the VPC.
- **`subnets`**: A list of subnet configurations, including names and CIDR blocks, within the VPC.
- **`dest_cidr`**: CIDR route for webapp subnet
- **`subnets`**: List of subnets with their names, CIDR ranges and private ip google access state.
- **`tag_name`**: Name of the tag in route

Define these variables in your `terraform.tfvars` file 

### Creating Resources

1. **Format Terraform**:
   ```bash
   terraform fmt
   ```
2. **Initialize Terraform**:

   ```bash
   terraform init
   ```
3. **Validate Terraform**:
   ```bash
   terraform validate
   ```
4. **Plan Terraform**:
   ```bash
   terraform plan
   ```
   Ensure that the plan matches with your expected resource configuration. If so, continue with next step or change config.
5. **Apply Terraform**:
   ```bash
   terraform apply
   ```
## To create multiple resources with same configuration

We can use [Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces) to create multiple resources with destroying previously created resources as multiple workspaces allow multiple states to be associated with single configuration file.

#### Using Workspace

Terraform starts with a single, default workspace named default that you cannot delete. If you have not created a new workspace, you are using the default workspace in your Terraform working directory.

1. **Create Workspace**:
    ```bash
    terraform workspace new <workspace_name>
    ```
Follow the same steps we used for creating resources

2. **Switch between workspace**:
   ```bash
   terraform workspace select <workspace_name>
    ```
Creating resources in different workspaces ensures the old resources created in previous workspace are not destroyed

## Assignment 4: Updated Resources

### Firewall

For this assignment, we have updated the Terraform template to include firewall rules:

- Firewall rules are set up for our custom VPC/Subnet to allow traffic from the internet to the port our application listens to.
- Traffic to deny all other is added using second firewall rule .

### Compute Engine Instance (VM)

We have also added a Compute Engine instance with the following specifications:

- Boot disk Image: Custom Image (Created after successful web app repo workflow)
- Boot disk type: Balanced
- Size (GB): 100

The instance is launched in the VPC created by our Terraform IaC code, ensuring it is not launched in the default VPC.
The vars.tf file has the additional variables added for these new resources.

### All resources in this config file
- 1 Virtual Private Cloud (VPC)
- 2 subnets namely "webapp" and "db"
- 1 route for the created VPC
- 1 compute instance launched in one of the subnets
- 2 Firewall rules for VPC - one to allow http requests and one to deny all with respective priorities
  
## Usage

To use the Terraform templates:

1. Clone this repository to your local machine.
2. Navigate to the directory containing the Terraform files.
3. Provide all the required variables mentioned in vars.tf file.
4. Run the steps mentioned above in create resources section

## Notes

Make sure you have the necessary permissions and credentials configured to interact with the Google Cloud Platform APIs.

## Final Step
After completion of project, remember to revoke google auth using below commands:
```bash
  gcloud auth revoke
  gcloud auth application-default revoke
```