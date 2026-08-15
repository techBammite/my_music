output "alb_dns_name" {
  description = "Nom DNS de l'Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "cloudfront_domain_name" {
  description = "Nom de domaine de la distribution CloudFront"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "s3_media_bucket_name" {
  description = "Nom du bucket S3 pour les médias (audios/covers)"
  value       = aws_s3_bucket.media.id
}

output "s3_deploy_bucket_name" {
  description = "Nom du bucket S3 pour les releases de code applicatif"
  value       = aws_s3_bucket.deploy.id
}

output "asg_name" {
  description = "Nom de l'Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "rds_endpoint" {
  description = "Endpoint de la base de données RDS MySQL"
  value       = aws_db_instance.mysql.endpoint
  sensitive   = true
}
