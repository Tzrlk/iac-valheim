# Sets up the service-specific parts of the setup

variable "AdminList" {
	description = "Steam ids of admins."
	type        = set(string)
	default     = []
}

data "docker_image" "Valheim" {
	name = "tzrlk/valheim-server"
}

locals {
	ValheimPorts = {
		Min = 2456
		Max = 2458
	}
	ValheimStatusPort = 80
	ValheimSuperPort = 9001
	ContainerCfg = {
		Valheim = {
			name         = "valheim"
			image        = data.docker_image.Valheim.repo_digest
			essential    = true
			cpu          = 2000
			memory       = 4000
			environment = [
				# https://github.com/lloesche/valheim-server-docker?msclkid=579e1618cf0e11ecaf755c38b2fade9e#environment-variables
				{ name = "SERVER_NAME",          value = "Bunnings" },
				{ name = "SERVER_PORT",          value = tostring(local.ValheimPorts.Min) },
				{ name = "WORLD_NAME",           value = "Bunnings" },
				{ name = "BACKUPS_IF_IDLE",      value = "false" },
				{ name = "BACKUP_CRON",          value = "@hourly" },
				{ name = "STATUS_HTTP",          value = "true" },
				{ name = "STATUS_HTTP_PORT",     value = tostring(local.ValheimStatusPort) },
				{ name = "SUPERVISOR_HTTP",      value = "true" },
				{ name = "SUPERVISOR_HTTP_PORT", value = tostring(local.ValheimSuperPort) },
				{ name = "ADMINLIST_IDS",        value = join(" ", var.AdminList) },
			]
			portMappings = concat([
				{ containerPort = local.ValheimStatusPort },
				{ containerPort = local.ValheimSuperPort },
			], [
				for port in range(local.ValheimPorts.Min, local.ValheimPorts.Max + 1) :
					{ containerPort = port, protocol = "udp" }
			]),
			healthCheck = {
				command     = [ "CMD-SHELL", "/healthcheck.sh" ]
				startPeriod = 300
			}
			secrets = [{
				name      = "SERVER_PASS"
				valueFrom = aws_secretsmanager_secret.ServerPass.arn
			}]
			volumesFrom = []
			linuxParameters = {
				initProcessEnabled = true
				# Can't add SYS_NICE under fargate.
			}
		}
		# https://github.com/jangrewe/docker-ecs-route53
		DnsUpdater = {
			name      = "dnsupdater"
			image     = "vagalume/route53-updater:latest"
			essential = false
			cpu       = 48
			memory    = 96
			environment = [
				{ name = "AWS_ROUTE53_ZONEID", value = aws_route53_zone.Aetheric.zone_id },
				{ name = "AWS_ROUTE53_HOST",   value = "valheim.aetheric.co.nz" },
				{ name = "AWS_ROUTE53_TTL",    value = "3600" },
			]
			portMappings = []
			mountPoints  = []
			volumesFrom  = []
			linuxParameters = {
				initProcessEnabled = true
			}
		}
	}
}

resource "aws_ecs_task_definition" "Valheim" {
	family                = "valheim"
	container_definitions = jsonencode([
		local.ContainerCfg.Valheim,
		local.ContainerCfg.DnsUpdater,
	])
	requires_compatibilities = [ "FARGATE" ]

	execution_role_arn = aws_iam_role.ValheimTask.arn
	task_role_arn      = aws_iam_role.ValheimExec.arn
	cpu                = sum(values(local.ContainerCfg)[*]["cpu"])
	memory             = sum(values(local.ContainerCfg)[*]["memory"])
	network_mode       = "awsvpc"
	tags = {
		Cost = "Free"
	}
}

variable "RunServer" {
	description = "Whether or not to run the server."
	type        = bool
	default     = false
}
resource "aws_ecs_service" "Valheim" {
	name            = "valheim"
	cluster         = aws_ecs_cluster.Valheim.id
	task_definition = aws_ecs_task_definition.Valheim.id
	launch_type     = "FARGATE"

	enable_execute_command = true
	force_new_deployment   = true

	desired_count                      = var.RunServer ? 1 : 0
	deployment_minimum_healthy_percent = 0
	deployment_maximum_percent         = 100

	network_configuration {
		subnets          = [ aws_subnet.Subnet.id ]
		security_groups  = [ aws_security_group.Cluster.id ]
		assign_public_ip = true
	}

	tags = {
		Cost = "Moderate"
	}
}
