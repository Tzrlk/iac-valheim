# Sync config between EFS and S3

data "aws_iam_policy_document" "DataSyncTrust" {
	statement {
		actions = [ "sts:AssumeRole" ]
		principals {
			type        = "Service"
			identifiers = [ "datasync.amazonaws.com" ]
		}
	}
}
resource "aws_iam_role" "DataSync" {
	name_prefix         = "data-sync-"
	assume_role_policy  = data.aws_iam_policy_document.DataSyncTrust.json
	managed_policy_arns = [
		aws_iam_policy.ValheimEfs.arn,
		aws_iam_policy.ValheimS3.arn,
	]
	tags = {
		Cost = "Free"
	}
}

## DATA SYNC LOCATIONS #########################################################
resource "aws_datasync_location_efs" "Valheim" {
	for_each = toset([ "worlds", "backups" ])

	efs_file_system_arn = aws_efs_file_system.ServerStorage.arn
	subdirectory        = "/config/${each.key}"
	ec2_config {
		subnet_arn          = aws_subnet.Subnet.arn
		security_group_arns = [ aws_security_group.Storage.arn ]
	}
	tags = {
	}
}
resource "aws_datasync_location_s3" "Valheim" {
	for_each = toset([ "worlds", "backups" ])

	s3_bucket_arn    = aws_s3_bucket.Valheim.arn
	subdirectory     = "/${each.key}"
	s3_config {
		bucket_access_role_arn = aws_iam_role.DataSync.arn
	}
	tags = {
	}
}

## DATA SYNC TASKS #############################################################
resource "aws_datasync_task" "UploadWorlds" {
	name                     = "valheim-worlds"
	source_location_arn      = aws_datasync_location_s3.Valheim["worlds"].arn
	destination_location_arn = aws_datasync_location_efs.Valheim["worlds"].arn
	options {
		overwrite_mode = "NEVER"
	}
	tags = {
	}
}
resource "aws_datasync_task" "SlurpBackups" {
	name                     = "valheim-backups"
	source_location_arn      = aws_datasync_location_efs.Valheim["backups"].arn
	destination_location_arn = aws_datasync_location_s3.Valheim["backups"].arn
	tags = {
	}
}
