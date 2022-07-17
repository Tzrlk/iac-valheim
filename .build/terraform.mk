# Triggering terraform in various circumstances.

ROOT ?= ..

.PRECIOUS: \
	${TF_DIR}/terraform.tfstate

TF_DIR := ${ROOT}/src/terraform

TF_SOURCES: $(wildcard ${ROOT}/src/terraform/*.tf)
TF_CONFIGS: $(wildcard ${TF_DIR}/*.tfvars)

#: Runs terraform to make aws match the desired config.
apply: ${TF_DIR}/.terraform.tfstate.backup

# Update the state by doing a full plan + apply.
${TF_DIR}/.terraform.tfstate.backup: \
		${TF_DIR}/terraform.tfplan
	cd ${TF_DIR} && \
	terraform apply \
			$(shell basename ${<})

#: Generates an execution plan from the current code changes.
plan: ${TF_DIR}/terraform.tfplan

# Generate the execution plan for any needed changes.
${TF_DIR}/terraform.tfplan: \
		TF_SOURCES \
		TF_CONFIGS \
		${TF_DIR}/.terraform.lock.hcl \
		| ${TF_DIR}/.terraform/
	cd ${TF_DIR} && \
	terraform plan \
			-out=$(shell basename ${@})

# Lets just say the .terraform/ directory is a result of the lockfile.
${TF_DIR}/.terraform/: \
		${TF_DIR}/.terraform.lock.hcl

# Initialise (and upgrade) required providers, modules, etc.
${TF_DIR}/.terraform.lock.hcl: \
		${TF_DIR}/_main.tf # provider config
	cd ${TF_DIR} && \
	terraform init \
			-upgrade

# Create a human/machine readable version of the current plan.
${TF_DIR}/terraform.tfplan.json: \
		${TF_DIR}/terraform.tfplan
	cd ${TF_DIR} && \
	terraform show \
			-json \
		> $(subst ${TF_DIR}/,,${@})

#: Generate a drift report for the account.
drift: ${TF_DIR}/terraform.drift.json

# Drift Detection
${TF_DIR}/terraform.drift.json: \
		${TF_DIR}/terraform.tfstate \
		${TF_DIR}/.terraform.lock.hcl \
		${TF_DIR}/terraform.tfplan
	driftctl scan \
			--from tfstate://$(word 1,${^}) \
			--tf-lockfile $(word 2,${^}) \
			--output json://${@}
