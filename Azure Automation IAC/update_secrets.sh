#!/bin/bash

# The name of your Azure Key Vault
KEYVAULT_NAME="KV-PBI-Technical-Users"

# Check if the CSV file exists
if [ ! -f secrets.csv ]; then
    echo "Error: secrets.csv not found."
    exit 1
fi

# Read the CSV file line by line, skipping the header
tail -n +2 secrets.csv | while IFS=',' read -r Database Username NewPassword ExpiryDate AzureKeySecretName Message
do
    # Convert the date to the format required by Azure CLI (YYYY-MM-DDTHH:MM:SSZ)
    # This example assumes the time is not important, so we set it to midnight UTC.
    EXPIRY_DATE_FORMATTED=$(date -d "$ExpiryDate" -u +"%Y-%m-%dT00:00:00Z")

    echo "Updating secret: $AzureKeySecretName in Key Vault: $KEYVAULT_NAME"

    # Update the secret in Azure Key Vault
    az keyvault secret set \
        --vault-name "$KEYVAULT_NAME" \
        --name "$AzureKeySecretName" \
        --value "$NewPassword" \
        --content-type "$Username" \
        --expires "$EXPIRY_DATE_FORMATTED"

    # Check if the command was successful
    if [ $? -eq 0 ]; then
        echo "Successfully updated secret: $AzureKeySecretName"
    else
        echo "Error updating secret: $AzureKeySecretName"
    fi
done

echo "Script finished."
