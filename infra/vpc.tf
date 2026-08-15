data "aws_availability_zones" "available" {
  state = "available"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "mymusic-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "mymusic-igw"
  }
}

# Subnets Publics (AZ1 & AZ2)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "mymusic-public-subnet-${count.index + 1}"
  }
}

# Subnets Privés App (AZ1 & AZ2)
resource "aws_subnet" "private_app" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + 2)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "mymusic-private-app-subnet-${count.index + 1}"
  }
}

# Subnets Privés DB (AZ1 & AZ2)
resource "aws_subnet" "private_db" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 4)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "mymusic-private-db-subnet-${count.index + 1}"
  }
}

# Elastic IP pour NAT Gateway (cree uniquement si enable_nat_gateway est true)
resource "aws_eip" "nat" {
  count      = var.enable_nat_gateway ? 1 : 0
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "mymusic-nat-eip"
  }
}

# NAT Gateway (optionnel pour economiser les couts)
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "mymusic-nat-gw"
  }

  depends_on = [aws_internet_gateway.main]
}

# Route Table pour Subnets Publics
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "mymusic-public-rt"
  }
}

# Associations Route Table Publics
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table pour Subnets App (route via IGW par defaut en Free Tier, ou via NAT si active)
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id     = var.enable_nat_gateway ? null : aws_internet_gateway.main.id
    nat_gateway_id = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
  }

  tags = {
    Name = "mymusic-app-rt"
  }
}

# Associations Route Table App
resource "aws_route_table_association" "private_app" {
  count          = 2
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}
