resource "aws_s3_bucket" "deploy" {
  bucket = "mymusic-app-deploy-${local.suffix}"

  force_destroy = true

  tags = {
    Name = "mymusic-app-deploy-bucket"
  }
}
