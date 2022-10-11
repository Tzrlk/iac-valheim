terraform {
	required_providers {
		aws = {
			source  = "hashicorp/aws"
			version = "~> 4.6"
		}
		docker = {
			source  = "kreuzwerker/docker"
			version = "~> 2.16"
		}
		external = {
			source  = "hashicorp/external"
			version = "~> 2.2.2"
		}
		http = {
			source  = "hashicorp/http"
			version = "~> 2.1"
		}
		local = {
			source  = "hashicorp/local"
			version = "~> 2.2.3"
		}
	}
}

provider "aws" {
	region = "ap-southeast-2"
	default_tags {
		tags = {
			Application = "Valheim"
		}
	}
}

provider "docker" {
	host = "tcp://localhost:2375"
}

module "ValheimServerAws" {
	source  = "tzrlk/valheim-server/aws"
	version = "0.1.0"

	world_name = "Bunnings"

	server_name     = "Bunnings"
	server_pass     = var.ServerPass
	server_timezone = "Pacific/Auckland"

	freedns_host  = "vikongs"
	freedns_token = var.DnsUpdaterToken
}

variable "ServerPass" {}
variable "DnsUpdaterToken" {}
