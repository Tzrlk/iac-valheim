# Set up EFS

resource "aws_efs_file_system" "ServerStorage" {
	lifecycle {
		prevent_destroy = true
	}
	lifecycle_policy {
		transition_to_ia = "AFTER_7_DAYS"
	}
	encrypted              = true
	availability_zone_name = aws_subnet.Subnet.availability_zone
	tags                   = {
		Cost = "Cheap"
	}
}

resource "aws_efs_mount_target" "ServerStorage" {
	file_system_id  = aws_efs_file_system.ServerStorage.id
	subnet_id       = aws_subnet.Subnet.id
	security_groups = [ aws_security_group.Storage.id ]
}

locals {
	EfsAccess = {
		config = {
			port  = local.EfsPort + 1
			mount = "/config"
		}
		data = {
			port = local.EfsPort + 2
			mount = "/opt/valheim"
		}
	}
}

resource "aws_efs_access_point" "ServerStorage" {
	for_each = local.EfsAccess

	file_system_id = aws_efs_file_system.ServerStorage.id
	root_directory {
		path = "/${each.key}"
		creation_info {
			owner_gid   = 0
			owner_uid   = 0
			permissions = "755"
		}
	}
	tags = {
		Cost = "Free"
	}
}

data "aws_iam_policy_document" "EfsAccess" {
	statement {
		resources = [ aws_efs_file_system.ServerStorage.arn ]
		actions = [
			"elasticfilesystem:ClientMount",
			"elasticfilesystem:ClientWrite",
			"elasticfilesystem:ClientRootAccess",
		]
		condition {
			variable = "elasticfilesystem:AccessPointArn"
			test     = "StringEquals"
			values   = values(aws_efs_access_point.ServerStorage)[*].arn
		}
	}
}
resource "aws_iam_policy" "ValheimEfs" {
	name   = "efs-access"
	policy = data.aws_iam_policy_document.EfsAccess.json
	tags = {
		Cost = "Free"
	}
}
