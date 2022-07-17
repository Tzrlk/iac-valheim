# Reporting on and controlling the ECS task

ROOT ?= ..
BUILD_DIR := ${ROOT}/.build
include ${BUILD_DIR}/config.mk

.SECONDARY: \
	${TASK_DIR}/svc_arn.txt \
	${TASK_DIR}/arn.txt \
	${TASK_DIR}/desc.json \
	${TASK_DIR}/eni.json \
	${TASK_DIR}/status.json
.INTERMEDIATE: \
	${TASK_DIR}/eni.txt \
	${TASK_DIR}/public_ip.txt \
	${TASK_DIR}/public_dns.txt

CLUSTER := valheim
CONTAINER := valheim

TASK_DIR := ${ROOT}/.build/task

${TASK_DIR}/:; mkdir -p ${@}

${TASK_DIR}/svc_arn.txt: | ${TASK_DIR}/
	@echo >&2 "> Checking for current service arn."
	aws ecs list-services --cluster "${CLUSTER}" \
		| jq -re '.serviceArns | first | select(length>0)' \
		> ${@}

${TASK_DIR}/arn.txt: .ALWAYS | ${TASK_DIR}/
	@echo >&2 "> Checking for current task arn." 
	@arn="$$(aws ecs list-tasks --cluster "${CLUSTER}" \
		| jq -re '.taskArns | first | select(length>0)')"
	@if [ -z "$${arn}" ]; then
		echo >&2 "> Task isn't running."; \
		exit 1; \
	elif [ "$${arn}" != "$(strip $(file < ${@}))" ]; then \
		echo >&2 "> Task ARN has changed to '$${arn}'."; \
		echo -n "$${arn}" > ${@}; \
	fi

${TASK_DIR}/desc.json: ${TASK_DIR}/arn.txt
	@echo >&2 "> Fetching task description."
	@desc="$$(aws ecs describe-tasks \
			--cluster "${CLUSTER}" \
			--tasks "$(file < ${<})" \
		| jq '.tasks | first | select(length>0)')"
	@if [ "$$(md5sum <<<"$${desc}")" != "$$(md5sum ${@})" ]; then \
		echo >&2 "> Task desc has changed."; \
		echo -n "$${desc}" > ${@}; \
	fi

${TASK_DIR}/eni.txt: ${TASK_DIR}/desc.json
	@echo >&2 "> Extracting ENI attached to task."
	@cat "${<}" \
		| jq -re '.attachments[].details[] | select(.name=="networkInterfaceId") | .value' \
		> ${@}
${TASK_DIR}/eni.json: ${TASK_DIR}/eni.txt
	@echo >&2 "> Fetching task ENI description."
	@aws ec2 describe-network-interfaces \
			--network-interface-ids "$(file < ${<})" \
		| jq -e '.NetworkInterfaces | first | select(length>0)' \
		> ${@}

${TASK_DIR}/public_ip.txt: ${TASK_DIR}/eni.json
	@echo >&2 "> Extracting public IP."
	@cat "${<}" \
		| jq -er '.Association.PublicIp' \
		> ${@}
${TASK_DIR}/public_dns.txt: ${TASK_DIR}/eni.json
	@echo >&2 "> Extracting public hostname."
	@cat "${<}" \
		| jq -er '.Association.PublicDnsName' \
		> ${@}

${TASK_DIR}/status.json: ${TASK_DIR}/public_ip.txt .ALWAYS
	@echo >&2 "> Fetching server status."
	@curl -s "http://$(file < ${<})/status.json" \
		| jq \
		> ${@}

addr: ${TASK_DIR}/public_ip.txt ${TASK_DIR}/public_dns.txt
	@echo "$(file < $(word 1,${^}))"
	@echo "$(file < $(word 2,${^}))"

#: Outputs the current server status
status: ${TASK_DIR}/status.json
	@cat ${<}

#: Connects to the running task
exec: ${TASK_DIR}/arn.txt
	@aws ecs execute-command \
		--cluster "${CLUSTER}" \
		--task "$(file < ${<})" \
		--container "${CONTAINER}" \
		--command 'bash' \
		--interactive

test: ${TASK_DIR}/public_ip.txt
	@echo >&2 "> Checking geekstrom api for Valheim response."
	@echo -e "2456: $$(curl -s "https://geekstrom.de/valheim/check/api.php?host=$(file < ${<})&port=2456")"
	@echo -e "2457: $$(curl -s "https://geekstrom.de/valheim/check/api.php?host=$(file < ${<})&port=2457")"

server-up: ${TASK_DIR}/svc_arn.txt
	@aws ecs update-service \
			--cluster "${CLUSTER}" \
			--service "$(file < ${<})" \
			--desired-count 1 \
			--force-new-deployment \
		| jq '.service.deployments'

server-down: ${TASK_DIR}/svc_arn.txt
	@aws ecs update-service \
			--cluster "${CLUSTER}" \
			--service "$(file < ${<})" \
			--desired-count 0 \
		| jq '.service.deployments'
