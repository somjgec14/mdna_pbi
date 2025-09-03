# Login
az login
# Checking accounts
az account list

# View Subscriptions
az account list
az account list --output table

# Set active subscriptions
az account set --subscription "Subscription Name or ID"

# Verify subscription
az account show

# Get help for commands
az --help
az group --help

# List resource groups
az group list --output table

# List resources in a resource group
az resource list --resource-group YourResourceGroupName --output table

# Create a resource group
az group create --name YourResourceGroupName --location eastus