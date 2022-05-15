# Permissions

data "aws_iam_policy_document" "EcsTrust" {
	statement {
		actions = [ "sts:AssumeRole" ]
		principals {
			identifiers = [ "ecs-tasks.amazonaws.com" ]
			type        = "Service"
		}
	}
}

## EXEC ROLE ###################################################################
data "aws_iam_policy" "AmazonECSTaskExecutionRolePolicy" {
	arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_policy" "AmazonECSTaskExecutionRolePolicy" {
	policy = data.aws_iam_policy.AmazonECSTaskExecutionRolePolicy.policy
	tags = {
		Cost = "Free"
	}
}
resource "aws_iam_role" "ValheimExec" {
	assume_role_policy = data.aws_iam_policy_document.EcsTrust.json
	managed_policy_arns = [
		aws_iam_policy.AmazonECSTaskExecutionRolePolicy.arn,
		aws_iam_policy.ServerPassAccess.arn,
		aws_iam_policy.SsmAccess.arn,
	]
	tags = {
		Cost = "Free"
	}
}

# TASK ROLE ####################################################################
resource "aws_iam_role" "ValheimTask" {
	assume_role_policy = data.aws_iam_policy_document.EcsTrust.json
	managed_policy_arns = [
		aws_iam_policy.ZoneRecordControl.arn,
		aws_iam_policy.ServerPassAccess.arn,
		aws_iam_policy.SsmAccess.arn,
	]
	tags = {
		Cost = "Free"
	}
}

data "aws_iam_policy_document" "SsmAccess" {
	statement {
		resources = [ "*" ]
		actions   = [
			"ssmmessages:CreateControlChannel",
			"ssmmessages:CreateDataChannel",
			"ssmmessages:OpenControlChannel",
			"ssmmessages:OpenDataChannel",
		]
	}
}
resource "aws_iam_policy" "SsmAccess" {
	name_prefix = "ssm-access-"
	policy = data.aws_iam_policy_document.SsmAccess.json
}