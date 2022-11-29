# instance type has a corresponding availability zone in each region
# here the availability zones are filtered by the resource aws_availability_zones
# ref: https://aws.amazon.com/tw/premiumsupport/knowledge-center/ec2-instance-type-not-supported-az-error/
data "aws_availability_zones" "available" {
  state = "available"
}

# set virtual private cloud (vpc)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "lemp stack"
  }
}

# set up internet gateways to allow communication between the instance in the vpc and the external internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet gateway"
  }
}

# set up the public subnet to put the app instance
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  # subnet availability zone needs to be the same as instance's availability zone
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.0.0.0/24"

  tags = {
    Name = "public subnet"
  }
}

# set up the private subnet to put the database instance
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  # subnet availability zone needs to be the same as instance's availability zone
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "private subnet"
  }
}

# set up the route table, enables network packets to flow in and out efficiently
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
  }

  tags = {
    Name = "private"
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# set public IP of app
resource "aws_eip" "app" {
  vpc      = true
  instance = aws_instance.app.id
}
