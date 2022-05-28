#!/usr/bin/env make

.ONESHELL:
.ALWAYS:
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


CLUSTER := valheim
CONTAINER := valheim

.make/: ; mkdir -p ${@}
.make/task/: | .make/ ; mkdir -p ${@}

.make/task/arn.txt: .ALWAYS | .make/task/
	arn="$$(aws ecs list-tasks --cluster "${CLUSTER}" \
		| jq -re '.taskArns | first | select(length>0)')"
	if [ "$$(md5sum <<<"$${arn}")" != "$$(md5sum ${@})" ]; then \
		echo >&2 "Task ARN has changed."; \
		echo "$${arn}" > ${@}; \
	fi

.make/task/desc.json: .make/task/arn.txt .ALWAYS
	desc="$$(aws ecs describe-tasks \
			--cluster "${CLUSTER}" \
			--tasks "$(file < ${<})" \
		| jq '.tasks | first | select(length>0)')"
	if [ "$$(md5sum <<<"$${desc}")" != "$$(md5sum ${@})" ]; then \
		echo >&2 "Task desc has changed."; \
		echo "$${desc}" > ${@}; \
	fi
	
.make/task/eni.txt: .make/task/desc.json
	cat "${<}" \
		| jq -re '.attachments[].details[] | select(.name=="networkInterfaceId") | .value' \
		> ${@}
.make/task/eni.json: .make/task/eni.txt .ALWAYS
	aws ec2 describe-network-interfaces \
			--network-interface-ids "$(file < ${<})" \
		| jq -e '.NetworkInterfaces | first | select(length>0)' \
		> ${@}

.make/task/public_ip.txt: .make/task/eni.json
	cat "${<}" \
		| jq -er '.Association.PublicIp' \
		> ${@}
.make/task/public_dns.txt: .make/task/eni.json
	cat "${<}" \
		| jq -er '.Association.PublicDnsName' \
		> ${@}

.make/task/status.json: .make/task/public_ip.txt .ALWAYS
	curl http://$(file < ${<})/status.json \
		| jq \
		> ${@}

addr: .make/task/public_ip.txt .make/task/public_dns.txt
	echo "$(file < $(word 1,${^}))"
	echo "$(file < $(word 2,${^}))"

#: Outputs the current server status
status: .make/task/status.json
	cat ${<}

#: Connects to the running task
exec: .make/task/arn.txt
	aws ecs execute-command \
		--cluster "${CLUSTER}" \
		--task "$(file < ${<})" \
		--container "${CONTAINER}" \
		--command 'bash' \
		--interactive
