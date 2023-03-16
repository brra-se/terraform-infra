variable "cname_record" {
  description = "Full name of the CNAME record to be used"
  type        = string
}

variable "s3_bucket_policy" {
  description = "Relative path to the S3 bucket policy"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone id"
  type        = string
}
