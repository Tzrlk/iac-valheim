# Sets up the service-specific parts of the setup

variable "AdminList" {
	description = "Steam ids of admins."
	type        = set(string)
	default     = []
}
variable "DynDnsPass" {
	description = "Password for the chosen dynamic dns service."
	type        = string
	sensitive   = true
}

data "docker_image" "Valheim" {
	name = "tzrlk/valheim-server"
}

locals {
	ValheimPorts = {
		Min    = 2456
		Max    = 2458
		Status = 80
		Super  = 9001
		Ddns   = 9002
	}
	TaskResFactors = {
		Cpu = 2
		Mem = 6
	}
	DnsUpdaterConfig = {
		settings = [{
			provider    = "freedns"
			domain      = "jumpingcrab.com"
			host        = "vikongs"
			token       = var.DynDnsPass
			ip_version  = "ipv4"
		}]
	}
	ContainerCfg = {
		Valheim = {
			name         = "valheim"
			image        = data.docker_image.Valheim.repo_digest
			essential    = true
			cpu          = 1000 * local.TaskResFactors.Cpu
			memory       = 1000 * local.TaskResFactors.Mem
			environment = [
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
				{ name = "TZ",                   value = "Pacific/Auckland" },
			]
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
			logConfiguration = {
				logDriver = "awslogs",
				options = {
					awslogs-group:         aws_cloudwatch_log_group.ValheimLogs.name
					awslogs-region:        "ap-southeast-2"
					awslogs-stream-prefix: "server"
				}
			}
			healthCheck = {
				command     = [ "CMD-SHELL", "/healthcheck.sh" ]
				interval    = 30
				retries     = 3
				timeout     = 5
				startPeriod = 300
			}
			secrets = [{
				name      = "SERVER_PASS"
				valueFrom = aws_secretsmanager_secret.ServerPass.arn
			}]
			mountPoints = []
			volumesFrom = []
			linuxParameters = {
				initProcessEnabled = true
				# Can't add SYS_NICE under fargate.
			}
		}
		# https://hub.docker.com/r/qmcgaw/ddns-updater
		DnsUpdater = {
			name      = "dnsupdater"
			image     = "qmcgaw/ddns-updater:latest"
			essential = false
			cpu       = 24 * local.TaskResFactors.Cpu
			memory    = 24 * local.TaskResFactors.Mem
			environment = [
				{ name = "CONFIG",         value = jsonencode(local.DnsUpdaterConfig) },
				{ name = "LISTENING_PORT", value = tostring(local.ValheimPorts.Ddns) },
				{ name = "TZ",             value = "Pacific/Auckland" },
			]
			portMappings = [{
				hostPort      = local.ValheimPorts.Ddns
				containerPort = local.ValheimPorts.Ddns
				protocol      = "tcp"
			}]
			mountPoints  = []
			volumesFrom  = []
			linuxParameters = {
				initProcessEnabled = true
			}
			healthCheck = {
				command     = [ "CMD-SHELL", "curl -f http://localhost:9999" ]
				interval    = 30
				retries     = 3
				timeout     = 5
				startPeriod = 300
			}
			logConfiguration = {
				logDriver = "awslogs",
				options = {
					awslogs-group:         aws_cloudwatch_log_group.ValheimLogs.name
					awslogs-region:        "ap-southeast-2"
					awslogs-stream-prefix: "ddns"
				}
			}
		}
	}
}

resource "aws_ecs_task_definition" "Valheim" {
	requires_compatibilities = [ "FARGATE" ]
	network_mode             = "awsvpc"

	execution_role_arn = aws_iam_role.ValheimTask.arn
	task_role_arn      = aws_iam_role.ValheimExec.arn

	cpu    = sum(values(local.ContainerCfg)[*]["cpu"])
	memory = sum(values(local.ContainerCfg)[*]["memory"])

	family                = "valheim"
	container_definitions = jsonencode([
		local.ContainerCfg.Valheim,
		local.ContainerCfg.DnsUpdater,
	])

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
	lifecycle {
		ignore_changes = [ desired_count ]
	}

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
