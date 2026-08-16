variable "aws_region" {
  description = "AWS Region for RDS deployment"
  type        = string
  default     = "eu-west-3"
}

variable "db_name" {
  description = "Name of the MySQL database"
  type        = string
  default     = "my_music"
}

variable "db_username" {
  description = "Master username for RDS MySQL"
  type        = string
  default     = "mymusic_admin"
}

variable "db_password" {
  description = "Master password for RDS MySQL"
  type        = string
  sensitive   = true
  default     = "MyMusicPassword2026!"
}
