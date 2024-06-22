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

module "vpc" {
  source = "./vpc"

  region               = var.region
  cidr_block           = var.cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  app_name             = var.app_name
}

resource "aws_security_group" "dip_private_sg" {
  name        = "dip_private_sg"
  description = "Allow SSH traffic from bastion host, TCP inbound traffic from public subnet, and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

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
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "${var.app_name}-private-ec2-${count.index + 1}"
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "${var.app_name}-ec2-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.app_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
