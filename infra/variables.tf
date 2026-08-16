variable "aws_region" {
  description = "Région AWS pour le déploiement"
  type        = string
  default     = "eu-west-3"
}

variable "environment" {
  description = "Nom de l'environnement (ex: dev, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "Bloc CIDR pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "Type d'instance EC2 pour l'Auto Scaling Group (t3.micro = AWS Free Tier)"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Nombre minimal d'instances dans l'ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Nombre maximal d'instances dans l'ASG"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Nombre désiré d'instances dans l'ASG"
  type        = number
  default     = 1
}

variable "db_name" {
  description = "Nom de la base de données MySQL"
  type        = string
  default     = "my_music"
}

variable "db_username" {
  description = "Nom d'utilisateur administrateur de la BDD"
  type        = string
  default     = "mymusic_admin"
}

variable "app_port" {
  description = "Port d'écoute de l'application Node.js"
  type        = number
  default     = 3000
}

variable "enable_nat_gateway" {
  description = "Activer la NAT Gateway payante. Mettre false pour rester 100% dans le AWS Free Tier."
  type        = bool
  default     = false
}

variable "multi_az_db" {
  description = "Activer Multi-AZ sur RDS MySQL. Mettre false pour le Free Tier."
  type        = bool
  default     = false
}
