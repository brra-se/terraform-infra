terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

## ---------------------------------------------------------------------------------------------------------------------
## Set up Droplet Instances
## ---------------------------------------------------------------------------------------------------------------------
data "digitalocean_kubernetes_versions" "default" {
  version_prefix = "1.26."
}

resource "digitalocean_kubernetes_cluster" "sgp1" {
  name         = "sgp1-cluster"
  region       = "sgp1"
  auto_upgrade = true
  version      = data.digitalocean_kubernetes_versions.default.latest_version

  maintenance_policy {
    start_time = "04:00"
    day        = "sunday"
  }

  node_pool {
    name       = "microservice-autoscale-worker-pool"
    size       = "s-1vcpu-2gb"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 2
  }
}
