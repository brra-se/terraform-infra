terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

resource "cloudflare_record" "a-record" {
  for_each = toset(var.subdomains)
  zone_id  = var.cloudflare_zone_id
  name     = each.key
  value    = var.aws_public_eip
  type     = "A"
  proxied  = true
}
