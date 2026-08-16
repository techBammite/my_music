variable "aws_region" {
  description = "AWS Region for deployment"
  type        = string
  default     = "eu-west-3"
}

variable "smtp_host" {
  description = "SMTP Server Host"
  type        = string
  default     = "smtp.hostinger.com"
}

variable "smtp_port" {
  description = "SMTP Server Port"
  type        = string
  default     = "465"
}

variable "smtp_username" {
  description = "SMTP Username"
  type        = string
  default     = "my_musique@bammite.com"
}

variable "smtp_password" {
  description = "SMTP Password"
  type        = string
  sensitive   = true
  default     = "Aws_cour.isi.2026"
}

variable "smtp_from_email" {
  description = "SMTP From Email"
  type        = string
  default     = "my_musique@bammite.com"
}

variable "smtp_from_name" {
  description = "SMTP From Name"
  type        = string
  default     = "My musique"
}
