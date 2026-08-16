data "aws_availability_zones" "available" {
  state = "available"
}

# Utilisation du VPC par defaut du compte AWS (0 risque VpcLimitExceeded)
data "aws_vpc" "default" {
  default = true
}

# Creation de 2 subnets publics dedies dans 2 Availability Zones distinctes
resource "aws_subnet" "app_subnet" {
  count                   = 2
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = cidrsubnet(data.aws_vpc.default.cidr_block, 4, count.index + 8)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "mymusic-subnet-${count.index + 1}"
  }
}
