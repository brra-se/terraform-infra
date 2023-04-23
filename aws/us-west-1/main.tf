## ---------------------------------------------------------------------------------------------------------------------
## TERRAFORM SETUP
## Set AWS region and Cloudflare account API token
## ---------------------------------------------------------------------------------------------------------------------
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

provider "aws" {
  region = "us-west-1"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

## ---------------------------------------------------------------------------------------------------------------------
## CLOUDFLARE A RECORDS
## Bind A record subdomains to AWS EIP for services 
## ---------------------------------------------------------------------------------------------------------------------

module "status_a_records" {
  source = "../../modules/cloudflare_a_record"

  subdomains         = ["status", "uptime-kuma"]
  cloudflare_zone_id = var.pcc_cloudflare_zone_id
  aws_public_eip     = aws_eip.t2_micro.public_ip
}

module "shuttleday_status_a_records" {
  source = "../../modules/cloudflare_a_record"

  subdomains         = ["status"]
  cloudflare_zone_id = var.shuttleday_cloudflare_zone_id
  aws_public_eip     = aws_eip.t2_micro.public_ip
}

## ---------------------------------------------------------------------------------------------------------------------
## SERVER INFRASTRUCTURE
## ---------------------------------------------------------------------------------------------------------------------
## Set up EC2 instances
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "t2_micro" {
  ami                  = "ami-014d05e6b24240371" # Ubuntu 22.04 LTS
  iam_instance_profile = "S3-Full-Access"
  instance_type        = "t2.micro"
  availability_zone    = "us-west-1a"
  key_name             = "wireguard"

  network_interface {
    network_interface_id = aws_network_interface.t2_micro.id
    device_index         = 0
  }

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "t2-micro"
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## Set up networking
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-1"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.main.id
}

## ---------------------------------------------------------------------------------------------------------------------
## Define AWS Security Groups
## ---------------------------------------------------------------------------------------------------------------------
module "aws_security_group" {
  source = "../../modules/aws_security_groups"

  vpc_id = aws_vpc.main.id
}

## ---------------------------------------------------------------------------------------------------------------------
## Create NICs for EC2 instances
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_network_interface" "t2_micro" {
  subnet_id   = aws_subnet.subnet_1.id
  private_ips = ["10.0.1.50"]
  security_groups = [
    module.aws_security_group.allow_web_id,
    module.aws_security_group.allow_ssh_id,
    module.aws_security_group.allow_wireguard_id,
  ]
}

## ---------------------------------------------------------------------------------------------------------------------
## Create EIPs for EC2 instances
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_eip" "t2_micro" {
  instance = aws_instance.t2_micro.id
  vpc      = true

  depends_on = [
    aws_internet_gateway.main
  ]
}

