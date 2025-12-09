# Application Gateway for Containers Workshop - Infrastructure

This directory contains Terraform configuration for deploying the infrastructure needed for the Application Gateway for Containers (AGC) workshop.

## 🏗️ What Gets Deployed

The infrastructure configuration creates:

- **Resource Group** - Container for all Azure resources
- **Virtual Network** - Network infrastructure with dedicated AKS subnet
- **AKS Cluster** - Kubernetes cluster with:
  - Azure CNI Overlay networking mode
  - Cilium as the network data plane
  - System node pool (2-4 nodes, autoscaling)
  - User node pool (2-4 nodes, autoscaling)
  - AzureLinux OS
- **Azure Container Registry (ACR)** - For storing container images
- **Network Security Group** - Basic security rules for HTTP/HTTPS traffic

## 📋 Prerequisites

### Required Tools

1. **Terraform** (>= 1.5)
   ```bash
   terraform version
   ```

2. **Azure CLI**
   ```bash
   az --version
   ```

3. **kubectl**
   ```bash
   kubectl version --client
   ```

### Azure Requirements

- Active Azure Subscription
- Sufficient permissions to create:
  - Resource Groups
  - AKS clusters
  - Azure Container Registry
  - Virtual Networks
  - Network Security Groups

## ⚙️ Configuration

### 1. Create terraform.tfvars

Copy the example file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your Azure subscription ID and desired base name:

```hcl
subscription_id = "12345678-1234-1234-1234-123456789abc"
base_name       = "agcworkshop"  # Only letters, no numbers or special characters
```

### 2. Optional Variables

You can override these defaults in your `terraform.tfvars`:

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `swedencentral` | Azure region |
| `virtual_network_address_prefix` | `10.0.0.0/16` | VNet address space |
| `aks_subnet_address_prefix` | `10.0.0.0/18` | AKS subnet range |
| `aks_service_cidr` | `192.168.0.0/20` | Kubernetes service CIDR |
| `aks_dns_service_ip` | `192.168.0.10` | Kubernetes DNS IP |
| `pod_cidr` | `10.244.0.0/16` | Pod CIDR for overlay network |

## 🚀 Deployment

### 1. Login to Azure

```bash
az login
az account set --subscription "your-subscription-id"
```

### 2. Initialize Terraform

```bash
cd IaC/infra
terraform init
```

### 3. Review the Plan

```bash
terraform plan -var-file="../terraform.tfvars"
```

### 4. Apply the Configuration

```bash
terraform apply -var-file="../terraform.tfvars" -auto-approve
```

The deployment typically takes 10-15 minutes.

### 5. Configure kubectl Access

After deployment completes, configure kubectl to access your AKS cluster:

```bash
az aks get-credentials --resource-group <resource-group-name> --name <cluster-name>
```

Or use the output values:

```bash
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
```

Verify access:

```bash
kubectl get nodes
```

## 📊 Outputs

After successful deployment, Terraform provides these outputs:

- `resource_group_name` - Name of the resource group
- `aks_cluster_name` - Name of the AKS cluster
- `aks_cluster_id` - Full resource ID of the AKS cluster
- `acr_name` - Name of the container registry
- `acr_login_server` - ACR login server URL
- `vnet_name` - Name of the virtual network
- `vnet_id` - Virtual network resource ID
- `aks_subnet_id` - AKS subnet resource ID

View outputs:

```bash
terraform output
```

## 🧹 Cleanup

To destroy all infrastructure resources:

```bash
terraform destroy -var-file="../terraform.tfvars" -auto-approve
```

⚠️ **Warning:** This will permanently delete all resources created by this configuration.

## 🔍 Troubleshooting

### Authentication Issues
```bash
az login
az account show
```

### Insufficient Permissions
Verify you have Contributor or Owner role on the subscription.

### Resource Name Conflicts
Use a unique `base_name` value to avoid naming conflicts.

### Quota Limits
Check your subscription has sufficient quota for:
- VM cores (requires ~16 cores for default setup)
- Public IPs
- Load balancers

## 📝 Network Architecture

```
Virtual Network (10.0.0.0/16)
└── AKS Subnet (10.0.0.0/18)
    ├── System Node Pool (2-4 nodes)
    └── User Node Pool (2-4 nodes)

Service CIDR: 192.168.0.0/20
Pod CIDR: 10.244.0.0/16 (Overlay)
```

## 🔄 Next Steps

After infrastructure deployment:

1. Deploy the application components (see `../app/README.md`)
2. Configure Application Gateway for Containers
3. Follow the workshop instructions
4. Explore AGC features and capabilities

## 📚 Additional Resources

- [Application Gateway for Containers Documentation](https://learn.microsoft.com/azure/application-gateway/for-containers/overview)
- [AKS CNI Overlay Documentation](https://learn.microsoft.com/azure/aks/azure-cni-overlay)
- [Cilium Documentation](https://docs.cilium.io/)
