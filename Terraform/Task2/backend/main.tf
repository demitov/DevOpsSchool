terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.1.0"
    }
  }
  required_version = "~>1.0"
}

provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Owner = "dmitrii_demitov@epam.com"
    }
  }
}

# Create S3 bucket
resource "aws_s3_bucket" "s3-tf-state" {
  bucket = "tf-state-demitov"
}

resource "aws_s3_bucket_acl" "s3-tf-state-acl" {
  bucket = aws_s3_bucket.s3-tf-state.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "s3-tf-state-ver" {
  bucket = aws_s3_bucket.s3-tf-state.id
  versioning_configuration {
    status = "Enabled"
  }
}
