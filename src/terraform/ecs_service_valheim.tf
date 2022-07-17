# Sets up the configuration specific to the valheim container.

variable "AdminList" {
	description = "Steam ids of admins."
	type        = set(string)
	default     = []
}

# Build and upload the image to the registry.
data "docker_registry_image" "Valheim" {
	name = "tzrlk/valheim-server:latest"
}

variable "ServerPass" {
	description = "The password for the Valheim server."
	type        = string
	sensitive   = true
}
resource "aws_secretsmanager_secret_version" "ServerPass" {
	lifecycle { ignore_changes = [ version_stages ] }

	secret_id     = aws_secretsmanager_secret.Password["Valheim"].arn
	secret_string = var.ServerPass
}

locals {
	ContainerValheim = merge(local.ContainerDefaults, {
		name         = "valheim"
		image        = data.docker_registry_image.Valheim.sha256_digest
		essential    = true
		cpu          = 1000 * local.TaskResFactors.Cpu
		memory       = 1000 * local.TaskResFactors.Mem
		environment = concat(local.ContainerDefaults.environment, [
			# https://github.com/lloesche/valheim-server-docker?msclkid=579e1618cf0e11ecaf755c38b2fade9e#environment-variables
			{ name = "SERVER_NAME",          value = "Bunnings" },
			{ name = "SERVER_PORT",          value = tostring(local.ValheimPorts.Min) },
			{ name = "WORLD_NAME",           value = "Bunnings" },
			{ name = "BACKUPS_IF_IDLE",      value = "false" },
			{ name = "BACKUP_CRON",          value = "@hourly" },
			{ name = "STATUS_HTTP",          value = "true" },
			{ name = "STATUS_HTTP_PORT",     value = tostring(local.ValheimPorts.Status) },
			{ name = "SUPERVISOR_HTTP",      value = "true" },
			{ name = "SUPERVISOR_HTTP_PORT", value = tostring(local.ValheimPorts.Super) },
			{ name = "ADMINLIST_IDS",        value = join(" ", var.AdminList) },
			{ name = "DNS_1",                value = "10.0.0.2" },
			{ name = "DNS_2",                value = "10.0.0.2" },
		])
		secrets = [{
			name      = "SERVER_PASS"
			valueFrom = aws_secretsmanager_secret.Password["Valheim"].arn
		}]
		portMappings = concat([
			for port in [ local.ValheimPorts.Status, local.ValheimPorts.Super ] : {
				hostPort = port
				containerPort = port
				protocol = "tcp"
			}
		], [
			for port in range(local.ValheimPorts.Min, local.ValheimPorts.Max + 1) : {
				hostPort = port
				containerPort = port
				protocol = "udp"
			}
		])
		logConfiguration = merge(local.ContainerDefaults.logConfiguration, {
			options = merge(local.ContainerDefaults.logConfiguration.options, {
				awslogs-stream-prefix : "valheim"
			})
		})
		healthCheck = merge(local.ContainerDefaults.healthCheck, {
			command     = [ "CMD-SHELL", "/healthcheck.sh" ]
			startPeriod = 300
		})
	})
}
