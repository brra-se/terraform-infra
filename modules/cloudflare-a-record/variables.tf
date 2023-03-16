variable "subdomains" {
  description = "List of strings for the A record subdomain"
  type        = list(string)
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone id to be deployed on"
  type        = string
}

variable "aws_public_eip" {
  description = "AWS EIP for redirects"
  type        = string
}
