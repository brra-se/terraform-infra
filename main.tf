## ---------------------------------------------------------------------------------------------------------------------
## TERRAFORM SETUP
## Set AWS region and Cloudflare account API token
## ---------------------------------------------------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "terraform-state-backend-s3"
    key            = "global/s3/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
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

provider "aws" {
  region = "ap-southeast-1"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

## ---------------------------------------------------------------------------------------------------------------------
## S3 BUCKET STATIC SITES
## Use local s3-static-site module to set up resources for static sites
## ---------------------------------------------------------------------------------------------------------------------
module "pcc" {
  source = "./modules/s3-static-site"

  cloudflare_zone_id = var.pcc_cloudflare_zone_id
  s3_bucket_policy   = "s3-policies/pcc-policy.json"
  cname_record       = "pierreccesario.com"
  site_redirect = {
    cname_record     = "www.pierreccesario.com"
    s3_bucket_policy = "s3-policies/www-pcc-policy.json"
  }
}
module "music-pcc" {
  source = "./modules/s3-static-site"

  cloudflare_zone_id = var.pcc_cloudflare_zone_id
  s3_bucket_policy   = "s3-policies/music-pcc-policy.json"
  cname_record       = "music.pierreccesario.com"
}
module "shuttleday" {
  source = "./modules/s3-static-site"

  cloudflare_zone_id = var.shuttleday_cloudflare_zone_id
  s3_bucket_policy   = "s3-policies/shuttleday-policy.json"
  cname_record       = "shuttleday.info"
  site_redirect = {
    cname_record     = "www.shuttleday.info"
    s3_bucket_policy = "s3-policies/www-shuttleday-policy.json"
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## CLOUDFLARE A RECORDS
## Bind A record subdomains to AWS EIP for services 
## ---------------------------------------------------------------------------------------------------------------------
module "api-shuttleday" {
  source = "./modules/cloudflare-a-record"

  subdomains         = ["api"]
  cloudflare_zone_id = var.shuttleday_cloudflare_zone_id
  aws_public_eip     = aws_eip.cicd-server-ip.public_ip
}

module "cicd-a-records" {
  source = "./modules/cloudflare-a-record"

  subdomains         = ["jenkins", "grafana", "prometheus", "sonarqube"]
  cloudflare_zone_id = var.pcc_cloudflare_zone_id
  aws_public_eip     = aws_eip.cicd-server-ip.public_ip
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS EC2 INFRASTRUCTURE
## ---------------------------------------------------------------------------------------------------------------------
## Set up EC2 instances
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "cicd-server" {
  ami                  = "ami-0255a102dbb96cef7"
  iam_instance_profile = "S3-Full-Access"
  instance_type        = "t3a.small"
  availability_zone    = "ap-southeast-1a"
  key_name             = "main-key"

  network_interface {
    network_interface_id = aws_network_interface.cicd-server-nic.id
    device_index         = 0
  }

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "CICD Server"
  }
}

# resource "aws_instance" "web-server" {
#   ami               = "ami-0255a102dbb96cef7"
#   instance_type     = "t2.micro"
#   availability_zone = "ap-southeast-1a"
#   key_name          = "main-key"

#   network_interface {
#     network_interface_id = aws_network_interface.web-server-nic.id
#     device_index         = 0
#   }

#   root_block_device {
#     volume_size = 10
#   }

#   tags = {
#     Name = "Web Hosting Server"
#   }
# }

## ---------------------------------------------------------------------------------------------------------------------
## Set up networking
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_vpc" "main-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "main-gateway" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "main-route-table" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main-gateway.id
  }

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id                  = aws_vpc.main-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-1"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.main-route-table.id
}

## ---------------------------------------------------------------------------------------------------------------------
## Define AWS Security Groups
## ---------------------------------------------------------------------------------------------------------------------
module "aws_security_group" {
  source = "./modules/aws-security-groups"

  vpc_id = aws_vpc.main-vpc.id
}

## ---------------------------------------------------------------------------------------------------------------------
## Create NICs for EC2 instances
## ---------------------------------------------------------------------------------------------------------------------
# resource "aws_network_interface" "web-server-nic" {
#   subnet_id   = aws_subnet.subnet-1.id
#   private_ips = ["10.0.1.50"]
#   security_groups = [
#     module.aws_security_group.allow_web_id,
#     module.aws_security_group.allow_ssh_id,
#     module.aws_security_group.allow_monitoring_traffic_id,
#     module.aws_security_group.allow_mongodb_id
#   ]
# }

resource "aws_network_interface" "cicd-server-nic" {
  subnet_id   = aws_subnet.subnet-1.id
  private_ips = ["10.0.1.60"]
  security_groups = [
    module.aws_security_group.allow_web_id,
    module.aws_security_group.allow_ssh_id,
    module.aws_security_group.allow_cicd_traffic_id,
    module.aws_security_group.allow_mongodb_id
  ]
}

## ---------------------------------------------------------------------------------------------------------------------
## Create EIPs for EC2 instances
## ---------------------------------------------------------------------------------------------------------------------
# resource "aws_eip" "public-web-server-ip" {
#   instance = aws_instance.web-server.id
#   vpc      = true

#   depends_on = [
#     aws_internet_gateway.main-gateway
#   ]
# }

resource "aws_eip" "cicd-server-ip" {
  instance = aws_instance.cicd-server.id
  vpc      = true

  depends_on = [
    aws_internet_gateway.main-gateway
  ]
}

## ---------------------------------------------------------------------------------------------------------------------
## REMOTE TF STATE
## Create S3 and DynamoDB resources to store remote Terraform state
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "terraform-state" {
  bucket = "terraform-state-backend-s3"

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform-state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform-state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public-access" {
  bucket                  = aws_s3_bucket.terraform-state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## MISCELLANEOUS
## ---------------------------------------------------------------------------------------------------------------------
## Create Shuttleday Payments S3 Bucket
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "shuttleday-payments" {
  bucket = "shuttleday-payments"
}
