# Creates an S3 bucket with public access for a static website, specifically a Hugo static website.
# Also creates an accompanying Cloudflare CNAME DNS record.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.38.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

resource "aws_s3_bucket" "static-site" {
  bucket = var.cname_record
}

resource "aws_s3_bucket_policy" "static-site" {
  bucket = aws_s3_bucket.static-site.id
  policy = file(var.s3_bucket_policy)
}

resource "aws_s3_bucket_acl" "static-site_bucket_acl" {
  bucket = aws_s3_bucket.static-site.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "static-site" {
  bucket = aws_s3_bucket.static-site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rules = <<EOF
[{
    "Condition": {
        "KeyPrefixEquals": "docs/"
    },
    "Redirect": {
        "ReplaceKeyPrefixWith": ""
    }
}]
EOF
}

resource "cloudflare_record" "static-site" {
  zone_id = var.cloudflare_zone_id
  name    = var.cname_record
  value   = aws_s3_bucket_website_configuration.static-site.website_endpoint
  type    = "CNAME"
  proxied = true
}
