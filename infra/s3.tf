# Bucket S3 pour le deploiement du code uniquement
resource "aws_s3_bucket" "deploy" {
  bucket = "mymusic-deploy-${local.suffix}"

  force_destroy = true

  tags = {
    Name = "mymusic-deploy-bucket"
  }
}
