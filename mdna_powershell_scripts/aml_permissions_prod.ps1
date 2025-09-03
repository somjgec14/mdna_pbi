# Azure Role Assignment and Synapse SQL Script
# Parameters
$subscriptionId = "ef6b3420-ecbc-474f-b106-474a6eed0aee"
$synapseWorkspaceName = "bbmrlsynwsprodwe001"
$keyVaultName = "kv-mdna-ml-we-prod-001"
$sqlPoolName = "bbmrlspprodwe001"
$systemAssignedIdentityId = "3a1d8cfd-195f-49b1-9bc7-4846c8fbf7ba"
$amlWorkspaceName = "aml-mdna-ml-we-prod-001"
$computeInstanceName = "mdna-ml-compute-cluster-001"

# Set the subscription context
Write-Host "Setting subscription context..." -ForegroundColor Cyan
try {
    Set-AzContext -SubscriptionId $subscriptionId
    Write-Host "Successfully set subscription context to: $subscriptionId" -ForegroundColor Green
} catch {
    Write-Host "Failed to set subscription context: $_" -ForegroundColor Red
    exit 1
}

# 1. Assign Contributor role to system-assigned identity
# a. On the Subscription
Write-Host "`nAssigning Contributor role on subscription level..." -ForegroundColor Cyan
try {
    New-AzRoleAssignment `
        -ObjectId $systemAssignedIdentityId `
        -RoleDefinitionName "Contributor" `
        -Scope "/subscriptions/$subscriptionId"
    Write-Host "Successfully assigned Contributor role on subscription" -ForegroundColor Green
} catch {
    Write-Host "Failed to assign Contributor role on subscription: $_" -ForegroundColor Red
}

# b. On the Synapse Workspace
Write-Host "`nAssigning Contributor role on Synapse Workspace..." -ForegroundColor Cyan
try {
    # Get Synapse Workspace resource group
    $synapseWorkspace = Get-AzSynapseWorkspace -Name $synapseWorkspaceName
    $synapseResourceGroup = $synapseWorkspace.ResourceGroupName
    
    New-AzRoleAssignment `
        -ObjectId $systemAssignedIdentityId `
        -RoleDefinitionName "Contributor" `
        -Scope "/subscriptions/$subscriptionId/resourceGroups/$synapseResourceGroup/providers/Microsoft.Synapse/workspaces/$synapseWorkspaceName"
    Write-Host "Successfully assigned Contributor role on Synapse Workspace" -ForegroundColor Green
} catch {
    Write-Host "Failed to assign Contributor role on Synapse Workspace: $_" -ForegroundColor Red
}

# c. On the Key Vault
Write-Host "`nAssigning Contributor role on Key Vault..." -ForegroundColor Cyan
try {
    # Get Key Vault resource group
    $keyVault = Get-AzKeyVault -VaultName $keyVaultName
    $kvResourceGroup = $keyVault.ResourceGroupName
    
    New-AzRoleAssignment `
        -ObjectId $systemAssignedIdentityId `
        -RoleDefinitionName "Contributor" `
        -Scope "/subscriptions/$subscriptionId/resourceGroups/$kvResourceGroup/providers/Microsoft.KeyVault/vaults/$keyVaultName"
    Write-Host "Successfully assigned Contributor role on Key Vault" -ForegroundColor Green
} catch {
    Write-Host "Failed to assign Contributor role on Key Vault: $_" -ForegroundColor Red
}

# 2. Assign Azure AI Administrator role on Key Vault
Write-Host "`nAssigning Azure AI Administrator role on Key Vault..." -ForegroundColor Cyan
try {
    New-AzRoleAssignment `
        -ObjectId $systemAssignedIdentityId `
        -RoleDefinitionName "Azure AI Administrator" `
        -Scope "/subscriptions/$subscriptionId/resourceGroups/$kvResourceGroup/providers/Microsoft.KeyVault/vaults/$keyVaultName"
    Write-Host "Successfully assigned Azure AI Administrator role on Key Vault" -ForegroundColor Green
} catch {
    Write-Host "Failed to assign Azure AI Administrator role on Key Vault: $_" -ForegroundColor Red
}

# 3. Grant SQL Permissions in Synapse SQL Pool
Write-Host "`nSetting up SQL permissions on Synapse SQL Pool..." -ForegroundColor Cyan

# Create SQL script file
$sqlScriptContent = @"
CREATE USER [$amlWorkspaceName/computes/$computeInstanceName] FROM EXTERNAL PROVIDER;
EXEC sp_addrolemember 'db_owner', '$amlWorkspaceName/computes/$computeInstanceName';
"@

$sqlScriptPath = "$env:TEMP\grant_permissions.sql"
$sqlScriptContent | Out-File -FilePath $sqlScriptPath -Encoding utf8

try {
    # To execute SQL commands, we need to use Invoke-Sqlcmd or another approach
    # Get the Synapse SQL endpoint
    $synapseEndpoint = "$synapseWorkspaceName.sql.azuresynapse.net"
    
    Write-Host "SQL script is ready to execute. Please run the following commands manually or use appropriate SQL tools:" -ForegroundColor Yellow
    Write-Host "-----------------------------------------" -ForegroundColor Yellow
    Write-Host $sqlScriptContent -ForegroundColor Yellow
    Write-Host "-----------------------------------------" -ForegroundColor Yellow
    Write-Host "Server: $synapseEndpoint" -ForegroundColor Yellow
    Write-Host "Database: $sqlPoolName" -ForegroundColor Yellow
    Write-Host "`nNote: You may need to use Azure Synapse Studio or SQL tools to execute these commands directly." -ForegroundColor Yellow

    # Alternative: If you have the appropriate SQL modules installed
    Write-Host "`nAttempting to execute SQL commands using Invoke-Sqlcmd..." -ForegroundColor Cyan
    Write-Host "If this fails, please use the manual approach described above." -ForegroundColor Yellow
    
    # Uncomment and use this if the Invoke-Sqlcmd module is available
    # Import-Module SqlServer
    # Invoke-Sqlcmd -ServerInstance $synapseEndpoint -Database $sqlPoolName -InputFile $sqlScriptPath -Username "<admin-username>" -Password "<admin-password>"
} catch {
    Write-Host "Failed to execute SQL commands: $_" -ForegroundColor Red
    Write-Host "Please execute the SQL commands manually as shown above." -ForegroundColor Yellow
}

Write-Host "`nScript execution completed!" -ForegroundColor Green