output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app.public_ip
}

output "app_url" {
  description = "Public HTTP URL of the MyMusic application"
  value       = "http://${aws_instance.app.public_ip}"
}

output "s3_deploy_bucket_name" {
  description = "S3 bucket for code deployment"
  value       = aws_s3_bucket.deploy.id
}
