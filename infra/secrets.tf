# Mot de passe DB aleatoire
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secret DB MySQL
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "mymusic/db_credentials_${local.suffix}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    host     = aws_db_instance.mysql.address
    port     = aws_db_instance.mysql.port
    dbname   = var.db_name
    username = var.db_username
    password = random_password.db_password.result
  })
}

# Secret SMTP Hostinger
resource "aws_secretsmanager_secret" "smtp_credentials" {
  name                    = "mymusic/smtp_credentials_${local.suffix}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "smtp_credentials" {
  secret_id = aws_secretsmanager_secret.smtp_credentials.id
  secret_string = jsonencode({
    SMTP_HOST       = "smtp.hostinger.com"
    SMTP_PORT       = 465
    SMTP_USERNAME   = "my_musique@bammite.com"
    SMTP_PASSWORD   = "Aws_cour.isi.2026"
    SMTP_FROM_EMAIL = "my_musique@bammite.com"
    SMTP_FROM_NAME  = "My musique"
  })
}
