terraform {
  backend "azurerm" {
    use_azuread_auth = true
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

resource "azurerm_subnet" "subnet-system" {
  name = "aks-system"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.0.0/24"]
  service_endpoints = [ "Microsoft.Storage" ]
}

resource "azurerm_subnet" "subnet-virtual" {
  name = "aks-virtual"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.4.0/24"]
  service_endpoints = [ "Microsoft.Storage" ]
  delegation {
    name = "aciDelegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "${var.BaseName}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.BaseName}aks"
  automatic_upgrade_channel = "rapid"
  node_os_upgrade_channel = "NodeImage"
  azure_policy_enabled = true
  workload_identity_enabled = true
  oidc_issuer_enabled = true

  linux_profile {
    admin_username = var.ADMINUSER
    ssh_key {
      key_data = var.SSHKEY
    }
  }

  lifecycle {
    ignore_changes = [ microsoft_defender ]
  }

  windows_profile {
    admin_username = var.ADMINUSER
    admin_password = var.WINDOWSADMINPASSWORD
  }

  network_profile {
    network_plugin = "azure"
    network_plugin_mode = "overlay"
    #Cilium doesn't support windows nodes
    #network_policy = "cilium"
    #network_data_plane = "cilium"
    dns_service_ip = "10.0.32.10"
    service_cidr = "10.0.32.0/24"
  }

  default_node_pool {
    name       = "system"
    vm_size    = "Standard_B4ms"
    auto_scaling_enabled = true
    max_count = 5
    min_count = 1
    vnet_subnet_id = azurerm_subnet.subnet-system.id
    only_critical_addons_enabled = true
    os_sku = "AzureLinux"

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

  aci_connector_linux {
    subnet_name = azurerm_subnet.subnet-virtual.name
  }

  oms_agent {
    log_analytics_workspace_id = var.LogAnalyticsWorkspaceId
    msi_auth_for_monitoring_enabled = true
  }

  monitor_metrics {}
  
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }
}

resource "azurerm_kubernetes_cluster_extension" "dapr" {
  name           = "dapr-ext"
  cluster_id     = azurerm_kubernetes_cluster.cluster.id
  extension_type = "Microsoft.Dapr"
}

#resource "azurerm_kubernetes_cluster_extension" "acs" {
#  name           = "acs-ext"
#  cluster_id     = azurerm_kubernetes_cluster.cluster.id
#  extension_type = "microsoft.azurecontainerstorage"
#}

resource "azurerm_subnet" "subnet-win19" {
  name = "aks-win19"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.1.0/24"]
  service_endpoints = [ "Microsoft.Storage" ]
}

resource "azurerm_kubernetes_cluster_node_pool" "windows2019-pool" {
  name = "win19"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id
  vm_size = "Standard_B4ms"
  auto_scaling_enabled = true
  max_count = 3
  min_count = 0
  os_type = "Windows"
  os_sku = "Windows2019"
  zones = []
  node_taints = []
  vnet_subnet_id = azurerm_subnet.subnet-win19.id

  upgrade_settings {
    max_surge = 1
  }

  tags = {}
}

resource "azurerm_subnet" "subnet-win22" {
  name = "aks-win22"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.2.0/24"]
  service_endpoints = [ "Microsoft.Storage" ]
}

resource "azurerm_kubernetes_cluster_node_pool" "windows2022-pool" {
  name = "win22"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id
  vm_size = "Standard_B4ms"
  auto_scaling_enabled = true
  max_count = 3
  min_count = 0
  os_type = "Windows"
  os_sku = "Windows2022"
  zones = []
  node_taints = []
  vnet_subnet_id = azurerm_subnet.subnet-win22.id

  upgrade_settings {
    max_surge = 1
  }

  tags = {}
}

resource "azurerm_subnet" "subnet-linux" {
  name = "aks-linux"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.0.3.0/24"]
  service_endpoints = [ "Microsoft.Storage" ]
}

resource "azurerm_kubernetes_cluster_node_pool" "linux-pool" {
  name = "linux"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.cluster.id
  vm_size = "Standard_B4ms"
  auto_scaling_enabled = true
  max_count = 3
  min_count = 0
  os_sku = "AzureLinux"
  zones = []
  node_taints = []
  vnet_subnet_id = azurerm_subnet.subnet-win22.id

  upgrade_settings {
    max_surge = 1
  }

  tags = {}
}