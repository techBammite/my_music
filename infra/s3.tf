# Bucket S3 pour les médias (audios et couvertures)
resource "aws_s3_bucket" "media" {
  bucket        = "mymusic-media-${local.suffix}"
  force_destroy = true

  tags = {
    Name = "mymusic-media-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS Rule pour permettre les requêtes d'upload HTML5 directes / canvas
resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "HEAD"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

# Bucket S3 pour les déploiements de code applicatif (releases zip)
resource "aws_s3_bucket" "deploy" {
  bucket        = "mymusic-deploy-${local.suffix}"
  force_destroy = true

  tags = {
    Name = "mymusic-deploy-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "deploy" {
  bucket = aws_s3_bucket.deploy.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
