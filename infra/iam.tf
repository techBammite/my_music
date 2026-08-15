# IAM Role pour EC2
resource "aws_iam_role" "ec2_role" {
  name = "mymusic-ec2-role-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Policy d'acces S3 et Secrets Manager pour EC2
resource "aws_iam_policy" "ec2_policy" {
  name        = "mymusic-ec2-policy-${random_id.suffix.hex}"
  description = "Autorise EC2 a lire les secrets et a interagir avec S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.media.arn,
          "${aws_s3_bucket.media.arn}/*",
          aws_s3_bucket.deploy.arn,
          "${aws_s3_bucket.deploy.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_credentials.arn,
          aws_secretsmanager_secret.smtp_credentials.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}

# Instance Profile pour l'ASG EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "mymusic-ec2-instance-profile-${random_id.suffix.hex}"
  role = aws_iam_role.ec2_role.name
}
