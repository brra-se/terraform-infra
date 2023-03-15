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
resource "cloudflare_record" "music-pcc" {
  zone_id = var.pcc_cloudflare_zone_id
  name    = "music"
  value   = aws_s3_bucket_website_configuration.music-pcc.website_endpoint
  type    = "CNAME"
  proxied = true
}
resource "cloudflare_record" "shuttleday" {
  zone_id = var.shuttleday_cloudflare_zone_id
  name    = "shuttleday.info"
  value   = aws_s3_bucket_website_configuration.shuttleday.website_endpoint
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "www-shuttleday" {
  zone_id = var.shuttleday_cloudflare_zone_id
  name    = "www"
  value   = aws_s3_bucket_website_configuration.www-shuttleday.website_endpoint
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "api-shuttleday" {
  zone_id = var.shuttleday_cloudflare_zone_id
  name    = "api"
  value   = aws_eip.cicd-server-ip.public_ip
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "jenkins" {
  zone_id = var.pcc_cloudflare_zone_id
  name    = "jenkins"
  value   = aws_eip.cicd-server-ip.public_ip
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "grafana" {
  zone_id = var.pcc_cloudflare_zone_id
  name    = "grafana"
  value   = aws_eip.cicd-server-ip.public_ip
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "prometheus" {
  zone_id = var.pcc_cloudflare_zone_id
  name    = "prometheus"
  value   = aws_eip.cicd-server-ip.public_ip
  type    = "A"
  proxied = true
}

resource "cloudflare_record" "sonarqube" {
  zone_id = var.pcc_cloudflare_zone_id
  name    = "sonarqube"
  value   = aws_eip.cicd-server-ip.public_ip
  type    = "A"
  proxied = true
}

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

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow http"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_traffic"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow ssh"
  }
}

resource "aws_security_group" "allow_cicd_traffic" {
  name        = "allow_cicd_traffic"
  description = "Allow CICD inbound traffic"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    description      = "Docker Registry"
    from_port        = 5000
    to_port          = 5000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Jenkins"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Sonarqube"
    from_port        = 9000
    to_port          = 9000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  tags = {
    Name = "allow cicd traffic"
  }
}

resource "aws_security_group" "allow_mongodb_traffic" {
  name        = "allow_mongodb_traffic"
  description = "Allow mongodb inbound traffic"
  vpc_id      = aws_vpc.main-vpc.id
  ingress {
    description      = "MongoDB"
    from_port        = 2500
    to_port          = 2500
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow mongodb traffic"
  }
}


resource "aws_security_group" "allow_monitoring_traffic" {
  name        = "allow_monitoring_traffic"
  description = "Allow monitoring inbound traffic"
  vpc_id      = aws_vpc.main-vpc.id
  ingress {
    description      = "Node Exporter"
    from_port        = 9100
    to_port          = 9100
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow monitoring traffic"
  }
}

# resource "aws_network_interface" "web-server-nic" {
#   subnet_id   = aws_subnet.subnet-1.id
#   private_ips = ["10.0.1.50"]
#   security_groups = [
#     aws_security_group.allow_web.id,
#     aws_security_group.allow_ssh.id,
#     aws_security_group.allow_monitoring_traffic.id,
#     aws_security_group.allow_mongodb_traffic.id
#   ]
# }

resource "aws_network_interface" "cicd-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.60"]
  security_groups = [aws_security_group.allow_web.id, aws_security_group.allow_ssh.id, aws_security_group.allow_cicd_traffic.id, aws_security_group.allow_mongodb_traffic.id]
}

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

resource "aws_s3_bucket" "terraform-state" {
  bucket = "terraform-state-backend-s3"

  # Prevent accidental deletion of this S3 bucket
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket" "shuttleday" {
  bucket = "shuttleday.info"
}

resource "aws_s3_bucket_policy" "shuttleday" {
  bucket = aws_s3_bucket.shuttleday.id
  policy = file("s3-policies/shuttleday-policy.json")
}

resource "aws_s3_bucket_acl" "shuttleday_bucket_acl" {
  bucket = aws_s3_bucket.shuttleday.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "shuttleday" {
  bucket = aws_s3_bucket.shuttleday.id

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

resource "aws_s3_bucket" "music-pcc" {
  bucket = "music.pierreccesario.com"
}

resource "aws_s3_bucket_policy" "music-pcc" {
  bucket = aws_s3_bucket.music-pcc.id
  policy = file("s3-policies/music-pcc-policy.json")
}

resource "aws_s3_bucket_acl" "music-pcc_bucket_acl" {
  bucket = aws_s3_bucket.music-pcc.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "music-pcc" {
  bucket = aws_s3_bucket.music-pcc.id

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

resource "aws_s3_bucket" "www-shuttleday" {
  bucket = "www.shuttleday.info"
}

resource "aws_s3_bucket_policy" "www-shuttleday" {
  bucket = aws_s3_bucket.www-shuttleday.id
  policy = file("s3-policies/www-shuttleday-policy.json")
}

resource "aws_s3_bucket_acl" "www_shuttleday_bucket_acl" {
  bucket = aws_s3_bucket.www-shuttleday.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "www-shuttleday" {
  bucket = aws_s3_bucket.www-shuttleday.id

  redirect_all_requests_to {
    host_name = aws_s3_bucket.shuttleday.bucket
  }
}

resource "aws_s3_bucket" "shuttleday-payments" {
  bucket = "shuttleday-payments"
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
