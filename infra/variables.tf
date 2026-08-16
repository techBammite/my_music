variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-3"
}

variable "instance_type" {
  description = "EC2 instance type (Free Tier eligible in eu-west-3: t3.micro)"
  type        = string
  default     = "t3.micro"
}
