terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.4"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}


provider "http" {}
data "http" "myip" {
  url = "https://ipinfo.io/json"
}

module "vpc" {
  source = "./vpc"

  region               = var.region
  cidr_block           = var.cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  app_name             = var.app_name
}

output "myip" {
  value = jsondecode(data.http.myip.response_body).ip
}

resource "aws_security_group" "dip_private_sg" {
  name        = "dip_private_sg"
  description = "Allow SSH traffic from bastion host, TCP inbound traffic from public subnet, and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/25"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.app_name}-private-sg"
  }
}

resource "aws_instance" "private_instance" {
  count                       = 2
  ami                         = "ami-033fabdd332044f06"
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.private_subnet_ids[count.index]
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.dip_private_sg.id]

  tags = {
    Name = "${var.app_name}-private-ec2=${count.index + 1}"
  }
}

resource "aws_security_group" "dip_bastion_host_sg" {
  name        = "dip_bastion_host_sg"
  description = "Allow SSH traffic from my IP address and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [format("%s/32", jsondecode(data.http.myip.response_body).ip)]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-bastion-host-sg"
  }
}

resource "aws_instance" "bastion_host" {
  ami                         = "ami-033fabdd332044f06"
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnet_ids[0]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = [aws_security_group.dip_bastion_host_sg.id]

  tags = {
    Name = "${var.app_name}-bastion-host-ec2"
  }
}
