# Role IAM pour l'instance EC2 de l'application principale
resource "aws_iam_role" "ec2_role" {
  name = "mymusic-app-ec2-role-${local.suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "mymusic-app-ec2-role"
  }
}

# Attach SSM Core managed policy for remote execution and management
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Policy for downloading release zip from S3 deploy bucket
resource "aws_iam_role_policy" "s3_read" {
  name = "mymusic-app-s3-read"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.deploy.arn,
        "${aws_s3_bucket.deploy.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "mymusic-app-ec2-profile-${local.suffix}"
  role = aws_iam_role.ec2_role.name
}
