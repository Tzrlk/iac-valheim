# Secret management

## SERVER PASS #################################################################
variable "ServerPass" {
	description = "The password for the Valheim server."
	type        = string
	sensitive   = true
}
resource "aws_secretsmanager_secret" "ServerPass" {
	name_prefix = "valheim-server-pass"
	tags = {
		Cost = "Cheap"
	}
}
resource "aws_secretsmanager_secret_version" "ServerPass" {
	lifecycle { ignore_changes = [ version_stages ] }
	secret_id = aws_secretsmanager_secret.ServerPass.arn
	secret_string = var.ServerPass
}

## RBAC ########################################################################
data "aws_iam_policy_document" "ServerPassAccess" {
	statement {
		actions   = [ "secretsmanager:GetSecretValue" ]
		resources = [ aws_secretsmanager_secret.ServerPass.arn ]
	}
}
resource "aws_iam_policy" "ServerPassAccess" {
	name   = "secrets-access"
	policy = data.aws_iam_policy_document.ServerPassAccess.json
	tags = {
		Cost = "Free"
	}
}
