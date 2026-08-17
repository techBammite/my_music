variable "aws_region" {
  description = "AWS Region for deployment"
  type        = string
  default     = "eu-west-3"
}

variable "db_host" {
  description = "RDS MySQL Hostname"
  type        = string
  default     = "mymusic-db-952b3825.cbi2io2eyuyd.eu-west-3.rds.amazonaws.com"
}

variable "db_port" {
  description = "RDS MySQL Port"
  type        = string
  default     = "3306"
}

variable "db_name" {
  description = "RDS MySQL Database Name"
  type        = string
  default     = "my_music"
}

variable "db_user" {
  description = "RDS MySQL Username"
  type        = string
  default     = "mymusic_admin"
}

variable "db_password" {
  description = "RDS MySQL Password"
  type        = string
  sensitive   = true
  default     = "MyMusicPassword2026!"
}
