terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://192.168.0.100:8006/api2/json"

  pm_api_token_id = var.api_id

  pm_api_token_secret = var.api_token_secret
}


# resource "proxmox_vm_qemu" "test" {
#   name        = "test"
#   target_node = "host"
#   iso         = "ISO-Storage:iso/ubuntu-22.04.2-live-server-amd64.iso"
#   vmid        = 134
# }

