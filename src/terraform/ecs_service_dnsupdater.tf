# https://hub.docker.com/r/qmcgaw/ddns-updater

# Make sure we know when the image changes.
data "docker_registry_image" "DnsUpdater" {
	name = "qmcgaw/ddns-updater:latest"
}

variable "DnsUpdaterToken" {
	description = "The token used to authenticate against the dns provider."
	type        = string
	sensitive   = true
}
locals {
	DnsUpdaterConfig = {
		provider    = "freedns"
		domain      = "jumpingcrab.com"
		host        = "vikongs"
		token       = var.DnsUpdaterToken
		ip_version  = "ipv4"
	}
}
resource "aws_secretsmanager_secret_version" "DnsUpdater" {
	lifecycle { ignore_changes = [ version_stages ] }

	secret_id     = aws_secretsmanager_secret.Password["DnsUpdater"].arn
	secret_string = jsonencode({
		settings = [ local.DnsUpdaterConfig ]
	})
}

locals {
	ContainerDns = merge(local.ContainerDefaults, {
		name        = "dnsupdater"
		image        = format("%s@%s",
			data.docker_registry_image.DnsUpdater.name,
			data.docker_registry_image.DnsUpdater.sha256_digest)
		cpu         = 24 * local.TaskResFactors.Cpu
		memory      = 24 * local.TaskResFactors.Mem
		environment = concat(local.ContainerDefaults.environment, [
			{ name = "LISTENING_PORT", value = tostring(local.ValheimPorts.Ddns) },
		])
		secrets = [{
			name      = "CONFIG"
			valueFrom = aws_secretsmanager_secret.Password["DnsUpdater"].arn
		}]
		portMappings = [{
			hostPort      = local.ValheimPorts.Ddns
			containerPort = local.ValheimPorts.Ddns
			protocol      = "tcp"
		}]
		healthCheck = merge(local.ContainerDefaults.healthCheck, {
			command = [ "CMD-SHELL", "curl -f http://localhost:9999" ]
		})
		logConfiguration = merge(local.ContainerDefaults.logConfiguration, {
			options = merge(local.ContainerDefaults.logConfiguration.options, {
				awslogs-stream-prefix : "dnsupdater"
			})
		})
	})
}
