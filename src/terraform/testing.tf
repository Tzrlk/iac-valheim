# Any resources needed for testing purposes.

resource "local_file" "DockerCompose" {
	filename = "${path.module}/../docker-compose.yml"
	content  = yamlencode({
		version  = "3.2"
		name     = "iac-valheim"
		services = {

			valheim = {
				container_name = local.ContainerValheim["name"]
				image          = local.ContainerValheim["image"]
				build          = {
					context = "docker"
				}
				volumes        = [ "~/.aws/:/root/.aws:ro" ]
				ports = [
					for item in local.ContainerValheim["portMappings"] :
						"${item["hostPort"]}:${item["containerPort"]}/${item["protocol"]}"
				]
				environment = {
					for item in local.ContainerValheim["environment"] :
						item["name"] => item["value"]
				}
				restart =           "always"
				stop_grace_period = "2m"
			}

			dnsupdater = {
				container_name = local.ContainerDns["name"]
				image          = local.ContainerDns["image"]
				volumes        = [ "~/.aws/:/root/.aws:ro" ]
				ports = [
					for item in local.ContainerDns["portMappings"] :
						"${item["hostPort"]}:${item["containerPort"]}/${item["protocol"]}"
				]
				environment = {
					for item in local.ContainerDns["environment"] :
						item["name"] => item["value"]
				}
			}

		}
	})
}
