variable "region" {
  default     = "eu-west-2"
  description = "The region the resources will be created in."
}

variable "profile" {
  type = string
  default = "exiimaster"
  description = "AWS profile to use"
}

provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

terraform {
  required_providers {
    aws = {
      version = "3.64.1"
    }
  }
}


resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"  
  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "exii-terraform-state"  # Enable versioning so we can see the full revision history of our
  # state files
  # region = "${var.region}"
  versioning {
    enabled = true
  }  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket              = "${aws_s3_bucket.terraform_state.id}"
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}