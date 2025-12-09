# Application Gateway for Containers Workshop

This directory contains all the assets needed for the AKS Application Gateway for Containers (AGC) workshop including Terraform configurations for deploying the complete Azure infrastructure.

## Prerequisites

### Required Tools

1. **Terraform (>= 1.5)**
   - [Download and install Terraform](https://www.terraform.io/downloads)
   - Verify installation: `terraform version`

2. **Azure CLI**
   - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
   - Verify installation: `az --version`

3. **kubectl**
   - [Install kubectl](https://kubernetes.io/docs/tasks/tools/)
   - Verify installation: `kubectl version --client`

### Azure Requirements

- Active Azure Subscription
- Sufficient Azure permissions to create:
  - Resource Groups
  - Azure Kubernetes Service (AKS) clusters
  - Azure Container Registry (ACR)
  - Virtual Networks and Subnets
  - App Service Domains
  - App Service Certificate Orders
  - Azure Key Vault
  - DNS Zones

### Authentication

Before deploying, authenticate with Azure:

```bash
az login
```

To verify you're using the correct subscription:

```bash
az account show
az account list --output table
```

To set a specific subscription:

```bash
az account set --subscription "<subscription-id>"
```

## Configuration

### Required Variables

Create a `terraform.tfvars` file in the `IaC` directory with the following required variables:

```hcl
subscription_id = "your-subscription-id"
base_name       = "your-unique-prefix"  # Used as prefix for all resources (lowercase letters and numbers only)
domain_contact_email = "your-email-address" # microsoft.com suffix is not supported
```

### Optional Variables

You can override these optional variables (defaults shown):

```hcl
region                         = "swedencentral"
virtual_network_address_prefix = "10.0.0.0/16"
aks_subnet_address_prefix      = "10.0.0.0/18"
aks_service_cidr               = "192.168.0.0/20"
aks_dns_service_ip             = "192.168.0.10"
pod_cidr                       = "10.244.0.0/16"
domain_suffix                  = "01"  # Appended to base_name for domain: {base_name}-{domain_suffix}.com
```

### Example terraform.tfvars

```hcl
subscription_id = "12345678-1234-1234-1234-123456789abc"
base_name       = "agcworkshop"
domain_contact_email = "blabla@gmail.com"
domain_suffix   = "01"
```

This will create a domain: `agcworkshop-01.com`

## Deployment Steps

### 1. Deploy Infrastructure

1. Navigate to the infrastructure directory:
   ```bash
   cd IaC/infra
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Apply the configuration:
   ```bash
   terraform apply -var-file="../terraform.tfvars" -auto-approve
   ```

5. Configure kubectl access to the AKS cluster:
   ```bash
   az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>
   ```
   
   The resource group and cluster names will be output after the apply completes.

### 2. Activate App Service Certificate

After the infrastructure deployment, you need to manually activate the wildcard SSL certificate:

1. Navigate to the [Azure Portal](https://portal.azure.com)

2. Go to **Resource Groups** and select the workshop resource group

3. Select your certificate (named `{base_name}-{domain_suffix}-wildcard`)

4. Click on **Certificate Configuration**

5. Follow the activation steps:
   
   **Step 1: Store Certificate in Key Vault**
   - Click **Step 1: Store**
   - Select the Key Vault created by Terraform (named `{base_name}-kv-{domain_suffix}`)
   - Click **OK**
   
   **Step 2: Verify Domain Ownership**
   - Click **Step 2: Verify**
   - Choose **Domain Verification** method (recommended for App Service Domains)
   - Wait for the verification to complete (this may take a few minutes)
   
   **Step 3: Validate Verification**
   - Return to the certificate configuration
   - Verify that all the steps need to be taken are completed

6. Once verified, the certificate status will change to **Issued**

**Note**: Domain verification can take up to 48 hours, but typically completes within a few minutes to a few hours.

## What Gets Deployed

This Terraform configuration creates:

**Infrastructure (`IaC/infra`)**:
- **Azure Container Registry (ACR)** - For storing container images
- **Azure Kubernetes Service (AKS)** - Managed Kubernetes cluster with:
  - CNI Overlay networking mode
  - Cilium network data plane
  - System and User node pools
- **Virtual Network** - Network infrastructure with dedicated AKS subnet
- **Network Security Group** - With HTTP/HTTPS traffic rules
- **App Service Domain** - Public .com domain registration
- **DNS Zone** - DNS management for the domain
- **App Service Certificate Order** - Wildcard SSL certificate (`*.yourdomain.com`)
- **Azure Key Vault** - Secure certificate storage and validation

## Clean Up

To destroy all created resources:

```bash
cd IaC/infra
terraform destroy -var-file="../terraform.tfvars"
```

⚠️ **Warning**: This will permanently delete all resources created by this configuration, including the registered domain and certificate.

## Troubleshooting

### Common Issues

1. **Authentication errors:**
   - Ensure you're logged in: `az login`
   - Verify correct subscription: `az account show`

2. **Insufficient permissions:**
   - Verify you have Contributor or Owner role on the subscription

3. **Resource name conflicts:**
   - Use a unique `base_name` to avoid naming conflicts

4. **Domain already exists:**
   - If the domain was previously created, Terraform may show update conflicts
   - The configuration uses `lifecycle.ignore_changes` to prevent these issues

5. **Certificate verification fails:**
   - Ensure the TXT record was added correctly to the DNS zone
   - Wait a few minutes for DNS propagation
   - Verify the DNS zone nameservers are correctly configured with your domain registrar

6. **Quota limits:**
   - Check your subscription has sufficient quota for VM cores and other resources

## Terraform Providers

This configuration uses:

- `azurerm` provider (v4.53.0) - Azure Resource Manager
- `azapi` provider (v2.7.0) - Azure API provider for resources not yet in azurerm

## Next Steps

After infrastructure deployment and certificate activation:

1. Deploy application workloads to AKS
2. Configure Application Gateway for Containers
3. Follow the workshop instructions for AGC capabilities demonstration

## Additional Resources

- [Azure Application Gateway for Containers Documentation](https://learn.microsoft.com/en-us/azure/application-gateway/for-containers/overview)
- [AKS CNI Overlay Documentation](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay)
- [Cilium Network Policies](https://docs.cilium.io/en/stable/network/kubernetes/policy/)
