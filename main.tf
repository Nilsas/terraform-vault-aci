locals {
  name = "cm-vault-demo"
}

resource "azurerm_resource_group" "main" {
  name     = format("rg-%s", local.name)
  location = "westeurope"
}

resource "azurerm_storage_account" "main" {
  name                     = replace(format("sa%s", local.name), "-", "")
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "main" {
  name                 = format("share-%s", local.name)
  storage_account_name = azurerm_storage_account.main.name
  quota                = 50
}

resource "azurerm_storage_share" "config" {
  name                 = format("config-%s", local.name)
  storage_account_name = azurerm_storage_account.main.name
  quota                = 25
}

resource "azurerm_storage_share_file" "config" {
  name             = "local.json"
  storage_share_id = azurerm_storage_share.config.id
  source           = "local.json"
  content_type     = "application/json"
}

resource "azurerm_container_group" "main" {
  name                = format("aci-%s", local.name)
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "public"
  dns_name_label      = format("aci-%s", local.name)
  os_type             = "Linux"

  container {
    name   = "vault"
    image  = "vault:latest"
    cpu    = "2"
    memory = "4"

    commands = ["vault", "server", "-config=/vault/config"]

    environment_variables = {
      SKIP_SETCAP = true
    }

    ports {
      port     = 8200
      protocol = "TCP"
    }

    volume {
      name       = "file"
      mount_path = "/vault/data"
      read_only  = false
      share_name = azurerm_storage_share.main.name

      storage_account_name = azurerm_storage_account.main.name
      storage_account_key  = azurerm_storage_account.main.primary_access_key
    }

    volume {
      name       = "config"
      mount_path = "/vault/config"
      read_only  = false
      share_name = azurerm_storage_share.config.name

      storage_account_name = azurerm_storage_account.main.name
      storage_account_key  = azurerm_storage_account.main.primary_access_key
    }
  }
}

resource "null_resource" "init" {
  provisioner "local-exec" {
    command = "pwsh -File ${path.module}/scripts/New-VaultSetup.ps1 -VaultAddress ${azurerm_container_group.main.fqdn}:8200"
  }
}

output "fqdn" {
  value = format("%s:8200", azurerm_container_group.main.fqdn)
}
