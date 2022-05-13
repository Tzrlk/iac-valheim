# Set up S3 Storage Archive for Valheim

## BUCKET ######################################################################
resource "aws_s3_bucket" "Valheim" {
	lifecycle {
		prevent_destroy = true
	}
	
	bucket_prefix  = "valheim-"
	hosted_zone_id = aws_subnet.Subnet.availability_zone_id
}
resource "aws_s3_bucket_acl" "Valheim" {
	bucket = aws_s3_bucket.Valheim.id
	acl    = "private"
}
resource "aws_s3_bucket_versioning" "Valheim" {
	bucket = aws_s3_bucket.Valheim.id
	versioning_configuration {
		status = "Enabled"
	}
}
resource "aws_s3_bucket_lifecycle_configuration" "Valheim" {
	depends_on = [ aws_s3_bucket_versioning.Valheim ]

	bucket = aws_s3_bucket.Valheim.id
	rule {
		id     = "store"
		status = "Enabled"
		filter {}
		abort_incomplete_multipart_upload {
			days_after_initiation = 1
		}
		transition {
			days          = 30
			storage_class = "ONEZONE_IA"
		}
		noncurrent_version_expiration {
			noncurrent_days           = 30
			newer_noncurrent_versions = 5
		}
	}
}

## IAM ACCESS ##################################################################
data "aws_iam_policy_document" "ValheimS3"  {
	statement {
		resources = [ aws_s3_bucket.Valheim.arn ]
		actions   = [
			"s3:ListBucket",
			"s3:LocateBucket",
			"s3:DescribeBucket",
			"s3:AbortMultipartUpload",
		]
	}
	statement {
		resources = [ "${aws_s3_bucket.Valheim.arn}/*" ]
		actions = [
			"s3:GetObject",
			"s3:PutObject",
			"s3:GetObjectAcl",
			"s3:PutObjectAcl",
			"s3:DeleteObject",
			"s3:DeleteObjectAcl",
		]
	}
}
resource "aws_iam_policy" "ValheimS3" {
	policy = data.aws_iam_policy_document.ValheimS3.json
}