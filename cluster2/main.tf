terraform {
  backend "azurerm" {
  }
}

provider "azurerm" {
  features {
  }
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "${var.BaseName}-aks"
  location            = var.Region
  resource_group_name = "mjgtest-rg"
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
    vnet_subnet_id = var.SubnetId

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