data "aws_availability_zones" "available" {
  state = "available"
}

# Utilisation du VPC par defaut du compte AWS (evite a 100% les erreurs VpcLimitExceeded)
data "aws_vpc" "default" {
  default = true
}

# Subnets par defaut du VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
