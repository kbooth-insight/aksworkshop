# Walkthrough with RBAC

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

Wait.

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
kubectl apply -f tiller-rbac-role.yml
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
Deploy captureorder.yml

```
kubectl apply -f captureorder.yml
```

Expose capture order service:
```
kubectl apply -f captureorder-service.yml
```

Wait for loadblancer to create and get IP.

Set variable to IP:
```
export CAPTUREORDERSERVICEIP=$(kubectl get service captureorder -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
```
Update frontend-deployment.yml to use your _the value of_ *CAPTUREORDERSERVICEIP* 
Then deploy frontend and expose it:

```
kubectl apply -f frontend-deployment.yml
kubectl apply -f frontend-service.yml
```

