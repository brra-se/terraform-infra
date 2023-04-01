terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.38.0"
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## ALLOW INBOUND AND OUTBOUND HTTP/S TRAFFIC
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

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

## ---------------------------------------------------------------------------------------------------------------------
## ALLOW INBOUND AND OUTBOUND SSH TRAFFIC
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_traffic"
  description = "Allow SSH inbound traffic"
  vpc_id      = var.vpc_id

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

## ---------------------------------------------------------------------------------------------------------------------
## ALLOW INBOUND TRAFFIC TO CICD SERVICES
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "allow_cicd_traffic" {
  name        = "allow_cicd_traffic"
  description = "Allow CICD inbound traffic"
  vpc_id      = var.vpc_id

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
    description      = "GitLab"
    from_port        = 8081
    to_port          = 8081
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow cicd traffic"
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## ALLOW INBOUND TRAFFIC TO MONGODB
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "allow_mongodb" {
  name        = "allow_mongodb"
  description = "Allow mongodb inbound traffic"
  vpc_id      = var.vpc_id
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

## ---------------------------------------------------------------------------------------------------------------------
## ALLOW INBOUND TRAFFIC TO NODE EXPORTER FOR MONITORING
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "allow_monitoring" {
  name        = "allow_monitoring"
  description = "Allow monitoring inbound traffic"
  vpc_id      = var.vpc_id
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
