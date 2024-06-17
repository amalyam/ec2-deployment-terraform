data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "dip-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = count.index == 0 ? "10.0.0.0/26" : "10.0.0.64/26"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "dip-public-subnet-$(count.index + 1)"
  }
}

resource "aws_subnet" "private_subnet" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = count.index == 0 ? "10.0.0.128/26" : "10.0.0.192/26"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "dip-private-subnet-$(count.index + 1)"
  }
}
