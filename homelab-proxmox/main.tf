terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  pm_api_url = var.api_url

  pm_api_token_id = var.api_id

  pm_api_token_secret = var.api_token_secret
}


resource "proxmox_lxc" "tailscale" {
  target_node  = "host"
  hostname     = "tailscale-home"
  unprivileged = true
  swap         = 512
  template     = false
  unique       = false
  onboot       = true
  cmode        = "tty"

  rootfs {
    storage = "ISO-Storage"
    size    = "4G"
  }
}


resource "proxmox_vm_qemu" "samba" {
  name                   = "Samba"
  target_node            = "host"
  bios                   = "seabios"
  onboot                 = true
  numa                   = false
  full_clone             = false
  agent                  = 1
  memory                 = 1024
  qemu_os                = "l26"
  scsihw                 = "virtio-scsi-single"
  oncreate               = false
  define_connection_info = false

  disk {
    type     = "scsi"
    storage  = "ISO-Storage"
    size     = "500G"
    backup   = true
    cache    = "none"
    file     = "105/vm-105-disk-0.qcow2"
    format   = "qcow2"
    iothread = 1
  }

  network {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = "true"
  }
}

