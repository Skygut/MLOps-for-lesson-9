resource "aws_s3_bucket" "tf_state" {
  bucket = var.bucket_name
  force_destroy = var.force_destroy
  tags = {
    Name        = var.bucket_name
    CreatedBy   = "Terraform"
    Description = "S3 bucket for Terraform state"
    Environment = var.tags["Environment"]
  }
}

resource aws_s3_bucket_versioning "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_public_access" {
    bucket = aws_s3_bucket.tf_state.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  
}