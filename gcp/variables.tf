variable "default_gcp_region" {
  type    = string
  default = "us-central1"
}

variable "default_gcp_zone" {
  type    = string
  default = "us-central1-a"
}

variable "gcp_project" {
  type = string
}

variable "k8s_machine_type" {
  type    = string
  default = "t2a-standard-2"
}

variable "bastion_machine_type" {
  type    = string
  default = "e2-micro"
}
