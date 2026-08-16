output "db_instance_identifier" {
  description = "RDS DB Instance Identifier"
  value       = aws_db_instance.mysql.identifier
}

output "db_endpoint" {
  description = "Full RDS MySQL Endpoint (Host:Port)"
  value       = aws_db_instance.mysql.endpoint
}

output "db_host" {
  description = "RDS MySQL Hostname"
  value       = aws_db_instance.mysql.address
}

output "db_port" {
  description = "RDS MySQL Port"
  value       = aws_db_instance.mysql.port
}

output "db_name" {
  description = "Database Name"
  value       = aws_db_instance.mysql.db_name
}

output "db_username" {
  description = "Database Master Username"
  value       = aws_db_instance.mysql.username
}

output "connection_test_command" {
  description = "CLI Command to test connection"
  value       = "mysql -h ${aws_db_instance.mysql.address} -P ${aws_db_instance.mysql.port} -u ${aws_db_instance.mysql.username} -p'MyMusicPassword2026!' ${aws_db_instance.mysql.db_name}"
}
