locals {
  mongo_db_connection_string_format = terraform.workspace == "prod" ? mongodbatlas_advanced_cluster.main.connection_strings[0].private_endpoint[0].srv_connection_string : mongodbatlas_advanced_cluster.main.connection_strings[0].standard_srv
  mongo_db_host                     = split("mongodb+srv://", local.mongo_db_connection_string_format)[1]
  mongo_db_connection_string        = "mongodb+srv://${mongodbatlas_database_user.root.username}:${mongodbatlas_database_user.root.password}@${local.mongo_db_host}/?retryWrites=true&w=majority"
}

resource "mongodbatlas_advanced_cluster" "main" {
  project_id   = var.mongo_atlas_project_id
  name         = "${terraform.workspace}-${var.prefix}-main"
  cluster_type = "REPLICASET"
  replication_specs {
    region_configs {
      electable_specs {
        instance_size = var.default_mongo_instance_size
        node_count    = 3
      }

      provider_name = "AZURE"
      priority      = 7
      region_name   = "EUROPE_WEST"
    }
  }

  depends_on = [
    mongodbatlas_privatelink_endpoint_service.azure-service
  ]
}

resource "mongodbatlas_database_user" "root" {
  username           = var.mongo_admin_user
  password           = var.mongo_admin_password
  project_id         = var.mongo_atlas_project_id
  auth_database_name = "admin"

  roles {
    role_name     = "readWriteAnyDatabase"
    database_name = "admin"
  }

  scopes {
    name = mongodbatlas_advanced_cluster.main.name
    type = "CLUSTER"
  }

}

resource "mongodbatlas_privatelink_endpoint" "azure-link" {
  count         = terraform.workspace == "prod" ? 1 : 0
  project_id    = var.mongo_atlas_project_id
  provider_name = "AZURE"
  region        = "westeurope"
}

resource "azurerm_private_endpoint" "atlasmongo" {
  count               = terraform.workspace == "prod" ? 1 : 0
  name                = "${terraform.workspace}-${var.prefix}-atlasmongo-private-endpoint"
  location            = azurerm_resource_group.abc.location
  resource_group_name = azurerm_resource_group.abc.name
  subnet_id           = azurerm_subnet.mongodb.id
  private_service_connection {
    name                           = mongodbatlas_privatelink_endpoint.azure-link[count.index].private_link_service_name
    private_connection_resource_id = mongodbatlas_privatelink_endpoint.azure-link[count.index].private_link_service_resource_id
    is_manual_connection           = true
    request_message                = "Azure Private Link"
  }
}

resource "mongodbatlas_privatelink_endpoint_service" "azure-service" {
  count                       = terraform.workspace == "prod" ? 1 : 0
  project_id                  = mongodbatlas_privatelink_endpoint.azure-link[count.index].project_id
  private_link_id             = mongodbatlas_privatelink_endpoint.azure-link[count.index].private_link_id
  endpoint_service_id         = azurerm_private_endpoint.atlasmongo[count.index].id
  private_endpoint_ip_address = azurerm_private_endpoint.atlasmongo[count.index].private_service_connection.0.private_ip_address
  provider_name               = "AZURE"
}