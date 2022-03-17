terraform {
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.BaseName}-rg"
  location = var.Region
}

resource "azurerm_virtual_network" "vnet" {
  name = "aks-vn"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name = "aks"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.0.0/22"]
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "${var.BaseName}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.BaseName}aks"
  automatic_channel_upgrade = "rapid"

  linux_profile {
    admin_username = var.AdminUser
    ssh_key {
      key_data = file(var.LinuxSSHKey)
    }
  }

  windows_profile {
    admin_username = var.AdminUser
    admin_password = var.WindowsAdminPassword
  }

  network_profile {
    network_plugin = "azure"
    dns_service_ip = "10.0.32.10"
    service_cidr = "10.0.32.0/24"
    docker_bridge_cidr = "172.17.0.0/16"
  }

  default_node_pool {
    name       = "system"
    vm_size    = "Standard_DS2_v2"
    enable_auto_scaling = true
    max_count = 3
    min_count = 1
    vnet_subnet_id = azurerm_subnet.subnet.id

    upgrade_settings {
      max_surge = 1
    }
  }

  identity {
    type = "SystemAssigned"
  }

  auto_scaler_profile {
    expander = "least-waste"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "windows-pool" {
  name = "win1"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id
  vm_size = "Standard_D8s_v3"
  enable_auto_scaling = true
  max_count = 3
  min_count = 0
  os_type = "Windows"
  availability_zones = []
  node_taints = []
  vnet_subnet_id = azurerm_subnet.subnet.id

  upgrade_settings {
    max_surge = 1
  }

  tags = {}
}