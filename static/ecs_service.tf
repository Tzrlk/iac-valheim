# Sets up the service-specific parts of the setup

locals {
	ComposeCfg = yamldecode(file("${path.module}/local/docker-compose.yml"))
	ValheimPorts = {
		Min = 2456
		Max = 2458
	}
	ContainerCfg = {
		Valheim = {
			name         = local.ComposeCfg["services"]["valheim"]["container_name"]
			image        = local.ComposeCfg["services"]["valheim"]["image"]
			essential    = true
			cpu          = 2000
			memory       = 4000
			environment = [
				for key, value in local.ComposeCfg["services"]["valheim"]["environment"] : {
					name  = key,
					value = value,
				}
			]
			portMappings = [
				for port in range(local.ValheimPorts.Min, local.ValheimPorts.Max + 1) : {
					containerPort = port
					hostPort      = port
					protocol      = "tcp"
				}
			]
			secrets = [{
				name      = "SERVER_PASS"
				valueFrom = aws_secretsmanager_secret.ServerPass.arn
			}]
			mountPoints = [
				for id, cfg in local.EfsAccess: {
					sourceVolume  = id
					containerPath = cfg.mount
				}
			]
			volumesFrom = []
			linuxParameters = {
				initProcessEnabled = true
			}
		}
		# https://github.com/jangrewe/docker-ecs-route53
		DnsUpdater = {
			name      = local.ComposeCfg["services"]["dnsupdater"]["container_name"]
			image     = local.ComposeCfg["services"]["dnsupdater"]["image"]
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

	execution_role_arn       = aws_iam_role.ValheimTask.arn
	task_role_arn            = aws_iam_role.ValheimExec.arn
	cpu                      = sum(values(local.ContainerCfg)[*]["cpu"])
	memory                   = sum(values(local.ContainerCfg)[*]["memory"])
	network_mode             = "awsvpc"
	dynamic "volume" {
		for_each = local.EfsAccess
		content {
			name = volume.key
			efs_volume_configuration {
				file_system_id          = aws_efs_file_system.ServerStorage.id
				transit_encryption      = "ENABLED"
				transit_encryption_port = volume.value["port"]
				authorization_config {
					access_point_id = aws_efs_access_point.ServerStorage[ volume.key ].id
				}
			}
		}
	}
	tags = {
		Cost = "Free"
	}
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

	desired_count                      = 1
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
