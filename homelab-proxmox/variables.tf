variable "api_url" {
  type = string
}

variable "api_id" {
  type      = string
  sensitive = true
}

variable "api_token_secret" {
  type      = string
  sensitive = true
}
