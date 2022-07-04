# Triggering terraform in various circumstances.

ROOT ?= ..

TF_DIR     := ${ROOT}/src/terraform
TF_SOURCES := $(wildcard ${ROOT}/src/terraform/*.tf)
TF_CONFIGS := $(wildcard ${TF_DIR}/*.tfvars)

#: Runs terraform to make aws match the desired config.
apply: ${TF_DIR}/.terraform.tfstate

${TF_DIR}/.terraform.tfstate ${TF_DIR}/.terraform.tfstate.backup &: \
		${TF_SOURCES} \
		${TF_CONFIGS} \
		${TF_DIR}/.terraform/
	cd ${TF_DIR} && \
	terraform apply

${TF_DIR}/.terraform/ ${TF_DIR}/.terraform.lock.hcl &: \
		${TF_DIR}/_main.tf # provider config
	cd ${TF_DIR} && \
	terraform init \
		--upgrade
