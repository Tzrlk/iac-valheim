#!/usr/bin/env make

.PHONY: \
	apply \
	exec

TF_DIR     := src/terraform
TF_SOURCES := $(wildcard src/terraform/*.tf)
TF_CONFIGS := $(wildcard src/terraform/*.tfvars)

apply: ${TF_DIR}/.terraform.tfstate

${TF_DIR}/.terraform.tfstate: \
		${TF_SOURCES} \
		${TF_CONFIGS} \
		${TF_DIR}/.terraform.lock.hcl
	cd ${TF_DIR} && \
	terraform apply

${TF_DIR}/.terraform.tfstate.backup: \
		.terraform.tfstate

${TF_DIR}/.terraform.lock.hcl: \
		src/terraform/_main.tf # provider config
	cd ${TF_DIR} && \
	terraform init \
		--upgrade

exec:
	sh bin/exec.sh

docker: \
	src/docker/Dockerfile
	docker build \
		--tag tzrlk/valheim-server:latest \ 
		src/docker/

ecr:
	aws ecr get-login-password \
	| docker login \
			--username AWS \
			--password-stdin \
			${DOCKER_REGISTRY}
