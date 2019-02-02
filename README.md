# Walkthrough with RBAC

Keep your service principal ID/secret handy.

Create analytics workspace and keep the key around to give to everyone as they get their captureorder services up:

```
az resource create \
    --resource-group akschallenge \
    --resource-type "Microsoft.Insights/components" \
    --name akschallengeproctor \
    --location eastus \
    --properties '{"Application_Type":"web"}' 
```

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

use the same credentials to create AKS cluster with RBAC:

```
az aks create --resource-group akschallenge --name <unique-aks-cluster-name> --enable-addons monitoring --kubernetes-version 1.11.5 --generate-ssh-keys --location eastus --service-principal APP_ID --client-secret "APP_SECRET"
```

Wait for awhile.

If you hit the dashboard now, you will get a lot of permissions errors. 

```
az aks browse -g <group> -n <cluster-name>
```

Run fix this to fixup the dashboard:
```
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
```

Because we created with RBAC we have to create a k8s service account in the kube-system namespace and give it cluster-admin role.  We can then assign this service account to different things.  We will use it for tiller/helm.

Run 
```
kubectl apply -f tiller-rbac-role.yaml
```
validate that it was created

```
➜  akschallenge git:(master) ✗ kubectl get sa -n kube-system tiller
NAME     SECRETS   AGE
tiller   1         10m
```

Initialize tiller giving it this account: 

```
tiller init --service-account tiller
```

Deploy mongoDB:
```
helm install stable/mongodb --name orders-mongo --set mongodbUsername=orders-user,mongodbPassword=orders-password,mongodbDatabase=akschallenge

```
Deploy captureorder.yaml

```
kubectl apply -f captureorder.yaml
```

Expose capture order service:
```
kubectl apply -f captureorder-service.yaml
```

Wait for loadblancer to create and get IP.

Set variable to IP:
```
export CAPTUREORDERSERVICEIP=$(kubectl get service captureorder -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
```
Update frontend-deployment.yaml to use your _the value of_ *CAPTUREORDERSERVICEIP* 
Then deploy frontend and expose it:

```
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
```

2.6 Scaling

Create load test container in ACI

```
az container create -g akschallenge -n loadtest --image azch/loadtest --restart-policy Never -e SERVICE_IP=<public ip of order capture service>
```


2.7

Create a registry, this 


Get the capture order source:
```
git clone https://github.com/Azure/azch-captureorder.git
cd azch-captureorder
```

Use ACR build to build image: 

NOTE:   We will probably need to do some coaching here on expectation.  This is really just showing them that they can build and push docker images with ACR.

It may be confusing if we follow that up with having them build the image in AzDevops possibly, clarification may be necessary

```
az acr build -t "captureorder:{{.Run.ID}}" -r <unique-acr-name> .

```

Grant the service princpal given to you by spektra permission to pull from the registry. 

```
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
```

