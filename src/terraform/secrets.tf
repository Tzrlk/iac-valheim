# Secret management

## SERVER PASS #################################################################
locals {
	Passwords = toset([
		"Valheim",
		"DnsUpdater",
	])
}
resource "aws_secretsmanager_secret" "Password" {
	for_each = local.Passwords

	name_prefix = "auth-pass-${lower(each.key)}-"
	tags = {
		Cost = "Cheap"
	}
}

## RBAC ########################################################################
data "aws_iam_policy_document" "PasswordAccess" {
	statement {
		actions   = [ "secretsmanager:GetSecretValue" ]
		resources = [
			for key in local.Passwords :
				aws_secretsmanager_secret.Password[key].arn
		]
	}
}
resource "aws_iam_policy" "PasswordAccess" {
	name   = "secrets-access"
	policy = data.aws_iam_policy_document.PasswordAccess.json
	tags = {
		Cost = "Free"
	}
}
