
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = var.tags
}

resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = merge(var.tags, { Name = "${var.name}-public-subnet-${count.index}" })
}

resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = element(var.availability_zones, count.index)
  tags = merge(var.tags, { Name = "${var.name}-private-subnet-${count.index}" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet_access" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)
  subnet_id = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "default_ssh" {
  name        = "${var.name}-default-ssh"
  description = "Default security group that allows only SSH traffic"
  vpc_id      = aws_vpc.main.id

  # Rule to allow SSH ingress
  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  
  }

  # Default to block all egress (outgoing traffic)
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"  # Allow all protocols
    cidr_blocks      = ["0.0.0.0/0"]  # Allow all outgoing traffic
  }

  tags = merge(var.tags, { Name = "${var.name}-default-ssh-sg" })
}
