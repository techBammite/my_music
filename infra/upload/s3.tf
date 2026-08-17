# Bucket S3 de stockage multimédia (fichiers audio MP3 & pochettes)
resource "aws_s3_bucket" "media" {
  bucket        = "mymusic-media-storage-${local.suffix}"
  force_destroy = true

  tags = {
    Name = "mymusic-media-storage"
  }
}

# Configuration CORS pour permettre le streaming audio et affichage d'images
resource "aws_s3_bucket_cors_configuration" "media_cors" {
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT", "POST"]
    allowed_origins = ["*"]
    max_age_seconds = 3600
  }
}
