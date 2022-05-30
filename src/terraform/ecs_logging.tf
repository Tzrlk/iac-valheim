# Set up logging for the valheim service

## Log Group ###################################################################
resource "aws_cloudwatch_log_group" "ValheimLogs" {
	name_prefix       = "valheim-server-"
	retention_in_days = 1
	tags              = {
		Cost = "Unknown"
	}
}

## Logging Permissions #########################################################
data "aws_iam_policy_document" "ValheimLogs" {
	statement {
		resources = [ aws_cloudwatch_log_group.ValheimLogs.arn ]
		actions   = [
			"logs:DescribeLogGroups",
		]
	}
	statement {
		resources = [ "${aws_cloudwatch_log_group.ValheimLogs.arn}:*" ]
		actions   = [
			"logs:CreateLogStream",
			"logs:DescribeLogStreams",
			"logs:PutLogEvents",
		]
	}
}
resource "aws_iam_policy" "ValheimLogs" {
	name_prefix = "valheim-server-logs-"
	policy      = data.aws_iam_policy_document.ValheimLogs.json
}
