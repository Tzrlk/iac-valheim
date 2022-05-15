terraform {
	required_providers {
		aws = {
			source  = "hashicorp/aws"
			version = "~> 4.6"
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
