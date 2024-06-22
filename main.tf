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
provider "tls" {

}
provider "local" {

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
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key" {
  key_name   = "dip2-key-pair"
  public_key = tls_private_key.private_key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.private_key.private_key_pem
  filename = "dip2-key-pair.pem"
}

resource "aws_security_group" "dip2_public_sg" {
  name        = "dip2_public_sg"
  description = "Allow SSH and TCP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [format("%s/32", jsondecode(data.http.myip.response_body).ip)]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dip2-public-sg"
  }
}

resource "aws_security_group" "dip2_private_sg" {
  name        = "dip2_private_sg"
  description = "Allow SSH traffic from bastion host, TCP inbound traffic from public subnet, and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.dip2_bastion_host_sg.id]
  }

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
    Name = "dip2-private-sg"
  }
}

resource "aws_security_group" "dip2_bastion_host_sg" {
  name        = "dip2_bastion_host_sg"
  description = "Allow SSH traffic from my IP address and all outbound traffic"
  vpc_id      = aws_vpc.main.id

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
    Name = "dip2-bastion-host-sg"
  }
}

resource "aws_instance" "public_instance" {
  ami                         = "ami-033fabdd332044f06"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = [aws_security_group.dip2_public_sg.id]

  tags = {
    Name = "dip2-public-ec2"
  }
}

resource "aws_instance" "private_instance" {
  ami                         = "ami-033fabdd332044f06"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_subnet.id
  associate_public_ip_address = false
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = [aws_security_group.dip2_private_sg.id]

  tags = {
    Name = "dip2-private-ec2"
  }
}

resource "aws_instance" "bastion_host" {
  ami                         = "ami-033fabdd332044f06"
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = [aws_security_group.dip2_bastion_host_sg.id]

  tags = {
    Name = "dip2-bastion-host-ec2"
  }
}
