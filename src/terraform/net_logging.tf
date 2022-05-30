# Sets up VPC flow logging for debugging network issues.

## LOGGING GROUP FOR FLOW LOGS #################################################
resource "aws_cloudwatch_log_group" "VpcFlowLogs" {
	name_prefix       = "valheim-flow-logs-"
	retention_in_days = 1
}

## ROLE FOR FLOW LOGS WRITING ##################################################
data "aws_iam_policy_document" "VpcFlowLogsTrust" {
	statement {
		actions = [ "sts:AssumeRole" ]
		principals {
			type        = "Service"
			identifiers = [ "vpc-flow-logs.amazonaws.com" ]
		}
	}
}
resource "aws_iam_role" "VpcFlowLogs" {
	name_prefix = "valheim-flow-logs-"
	assume_role_policy = data.aws_iam_policy_document.VpcFlowLogsTrust.json
}

## ACCESS TO FLOW LOGS #########################################################
data "aws_iam_policy_document" "VpcFlowLogsAccess" {
	statement {
		resources = [ aws_cloudwatch_log_group.VpcFlowLogs.arn ]
		actions   = [
			"logs:DescribeLogGroups",
		]
	}
	statement {
		resources = [ "${aws_cloudwatch_log_group.VpcFlowLogs.arn}:*" ]
		actions   = [
			"logs:CreateLogStream",
			"logs:DescribeLogStreams",
			"logs:PutLogEvents",
		]
	}
}
resource "aws_iam_role_policy" "VpcFlowLogs" {
	role   = aws_iam_role.VpcFlowLogs.id
	policy = data.aws_iam_policy_document.VpcFlowLogsAccess.json
}

## FLOW LOG ENABLEMENT #########################################################
variable "VpcFlowLogs" {
	description = "Monitor all network traffic in the VPC."
	type        = bool
	default     = false
}
resource "aws_flow_log" "VpcFlowLogs" {
	count = var.VpcFlowLogs ? 1 : 0

	log_destination = aws_cloudwatch_log_group.VpcFlowLogs.arn
	iam_role_arn    = aws_iam_role.VpcFlowLogs.arn

	vpc_id       = aws_vpc.Vpc.id
	traffic_type = "ALL"

	max_aggregation_interval = "60"

}