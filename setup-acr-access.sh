#!/usr/bin/env bash

AKS_RESOURCE_GROUP=rg-booth-akschallenge
AKS_CLUSTER_NAME=booth-akschallenge
ACR_RESOURCE_GROUP=$AKS_RESOURCE_GROUP
ACR_NAME=boothaksworkshop

# Get the id of the service principal configured for AKS
CLIENT_ID=$(az aks show --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME --query "servicePrincipalProfile.clientId" --output tsv)

# Get the ACR registry resource id
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $ACR_RESOURCE_GROUP --query "id" --output tsv)

# Create role assignment
az role assignment create --assignee $CLIENT_ID --role acrpull --scope $ACR_ID