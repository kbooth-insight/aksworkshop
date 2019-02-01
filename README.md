# walkthrough

Create an SP to use for the walkthrough (this should be provided to you by Spektra)

`az ad sp create-for-rbac --name booth-for-akschallenge`

```
{
  "appId": "xxxxxx-xxx-xxx-xxx-xxxxxx",
  "displayName": "booth-for-akschallenge",
  "name": "http://booth-for-akschallenge",
  "password": "xxxxxxxx-xxxx-xxxxx-xxxx-xxxxxx",
  "tenant": "xxxx-xx-xxxx-80xx2f-xxxxxxxx"
}
```

use credentials to create AKS cluster with RBAC:

```
az aks create --resource-group akschallenge --name <unique-aks-cluster-name> --enable-addons monitoring --kubernetes-version 1.11.5 --generate-ssh-keys --location eastus --service-principal APP_ID --client-secret "APP_SECRET"
```

Wait.

