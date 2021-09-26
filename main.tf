variable "aws_profile" { }
variable "aws_role" {}
variable "aws_region" { default = "eu-central-1" }
variable "owner" { default = "cloudops" }
variable "support" { default = "allianztechnology.th-apcp@allianz.com" }

locals {
  common_tags = {
    Owner = lower(var.owner)
    Environment = "none"
    Support = lower(var.support)
  }
}

provider "aws" {
  version        = "3.9.0"
  profile        = var.aws_profile
  region         = var.aws_region
  assume_role {
    role_arn     = var.aws_role
  }
}

resource "aws_s3_bucket" "helm_central" {
    bucket = "s3-cloudops-ec1-logging-charts-bucket"
    acl    = "private"
    versioning {
        enabled = true
    }
    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
    tags   = merge(local.common_tags, { 
        Name = "s3-cloudops-ec1-logging-charts-bucket"
    })
}

resource "aws_s3_bucket_policy" "access_policy" {
  bucket = aws_s3_bucket.helm_central.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowListObjects",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::657159750905:role/aztecse-gbmnp-nonprod-terraform-assumerole"
                ]
            },
            "Action": "s3:ListBucket",
            "Resource": "${aws_s3_bucket.helm_central.arn}"
        },
        {
            "Sid": "AllowObjectsFetchAndCreate",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::657159750905:role/aztecse-gbmnp-nonprod-terraform-assumerole"
                ]
            },
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": "${aws_s3_bucket.helm_central.arn}/*"
        }
    ]
}
POLICY
}

resource "aws_s3_bucket_object" "object" {
    bucket = aws_s3_bucket.helm_central.bucket
    key    = "index.yaml"
    source = "index.yaml"
}