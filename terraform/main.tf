provider "azurerm" {
  version = "~>1.21"
}

provider "null" {
  version = "~>2.0"
}

provider "helm" {
  version = "~> 0.7"
}

provider "random" {
  version = "2.0"
}

resource "azurerm_resource_group" "workshop_group" {
  name     = "rg-booth-${var.environment}"
  location = "${var.location}"
  tags     = "${var.tags}"
}


resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "${var.environment}proctor"
  location            = "eastus"
  resource_group_name = "${azurerm_resource_group.workshop_group.name}"
  sku                 = "Standard"
  retention_in_days   = 30
}

resource "azurerm_virtual_network" "workshop_vnet" {
  name                = "vnet-${var.environment}"
  address_space       = "${var.address_space}"
  location            = "${azurerm_resource_group.workshop_group.location}"
  resource_group_name = "${azurerm_resource_group.workshop_group.name}"
  tags                = "${var.tags}"
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet-${var.environment}"
  resource_group_name  = "${azurerm_resource_group.workshop_group.name}"
  virtual_network_name = "${azurerm_virtual_network.workshop_vnet.name}"
  address_prefix       = "${var.aks_address_prefix}"
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "aci_subnet" {
  name                 = "aci-subnet-${var.environment}"
  resource_group_name  = "${azurerm_resource_group.workshop_group.name}"
  virtual_network_name = "${azurerm_virtual_network.workshop_vnet.name}"
  address_prefix       = "${var.aci_address_prefix}"
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "aks-${var.environment}"
  location            = "${azurerm_resource_group.workshop_group.location}"
  resource_group_name = "${azurerm_resource_group.workshop_group.name}"
  dns_prefix          = "${var.environment}"
  kubernetes_version  = "${var.kubernetes_version}"

  network_profile {
    network_plugin = "azure"
  }

  #   linux_profile {
  #     admin_username = "${var.admin_username}"

  #   }
  addon_profile {
    aci_connector_linux {
      enabled     = true
      subnet_name = "${azurerm_subnet.aci_subnet.name}"
    }
  }
  role_based_access_control {
    enabled = true
  }
  agent_pool_profile {
    name           = "linuxprofile"
    count          = "2"
    os_type        = "Linux"
    vm_size        = "Standard_D2s_v3"
    vnet_subnet_id = "${azurerm_subnet.aks_subnet.id}"
  }
  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }
  tags {
    test = "blah"
  }
}

resource "null_resource" "setup_k8s" {
  provisioner "local-exec" {
    command = "az aks get-credentials --admin --overwrite-existing -g ${azurerm_resource_group.workshop_group.name} -n ${azurerm_kubernetes_cluster.aks_cluster.name}"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ../yaml/tiller-rbac-role.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard"
  }

  provisioner "local-exec" {
    command = "helm init --service-account tiller --wait"
  }

  provisioner "local-exec" {
    command = "helm install stable/mongodb --name orders-mongo --set mongodbUsername=orders-user,mongodbPassword=orders-password,mongodbDatabase=akschallenge --wait"

  }
  provisioner "local-exec" {
    command = "helm install ../provided-helm --set appInsightsKey=${azurerm_log_analytics_workspace.log_workspace.primary_shared_key}"
  }
}
