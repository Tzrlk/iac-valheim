#!/usr/bin/env make

.PHONY: \
	apply

TF_SOURCES := $(wildcard *.tf)
TF_CONFIG := $(wildcard *.tfvars)

apply: \
	.terraform.tfstate

.terraform.tfstate: \
		${TF_SOURCES} \
		${TF_CONFIG}
	terraform apply

.terraform.tfstate.backup: \
		.terraform.tfstate

.terraform.lock.hcl: \
		_main.tf # provider config
	terraform init \
		--upgrade
