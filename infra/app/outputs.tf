output "instance_id" {
  description = "EC2 Instance ID for Main Application"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "Public IP Address of the EC2 Instance"
  value       = aws_instance.app.public_ip
}

output "app_url" {
  description = "Public HTTP Web URL of the Main Application"
  value       = "http://${aws_instance.app.public_ip}"
}

output "s3_deploy_bucket_name" {
  description = "S3 Deploy Bucket Name for Main Application Code"
  value       = aws_s3_bucket.deploy.id
}
