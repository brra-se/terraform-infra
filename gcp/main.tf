terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.62.1"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.default_gcp_region
  zone    = var.default_gcp_zone
}

resource "google_compute_address" "us_public_ip" {
  name = "us-public-ip"
}

resource "google_compute_address" "sg_public_ip" {
  region = "asia-southeast1"
  name   = "sg-public-ip"
}

resource "google_compute_instance" "k8s_control_plane1" {
  name         = "k8s-control-plane1"
  machine_type = var.k8s_machine_type

  boot_disk {
    initialize_params {
      image = "rocky-linux-cloud/rocky-linux-9-optimized-gcp-arm64"
    }
  }

  network_interface {
    network    = "default"
    network_ip = "10.128.0.10"
    access_config {
      nat_ip = google_compute_address.us_public_ip.address
    }
  }
}

resource "google_compute_instance" "k8s_worker1" {
  name         = "k8s-worker1"
  machine_type = var.k8s_machine_type

  boot_disk {
    initialize_params {
      image = "rocky-linux-cloud/rocky-linux-9-optimized-gcp-arm64"
    }
  }

  network_interface {
    network    = "default"
    network_ip = "10.128.0.20"
  }
}

resource "google_compute_instance" "bastion_host" {
  name         = "bastion-host"
  machine_type = var.bastion_machine_type
  zone         = "asia-southeast1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = "default"
    network_ip = "10.148.0.10"
    access_config {
      nat_ip = google_compute_address.sg_public_ip.address
    }
  }
}
