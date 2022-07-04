# Reporting on and controlling the ECS task

.SECONDARY: \
	.make/task/svc_arn.txt \
	.make/task/arn.txt \
	.make/task/desc.json \
	.make/task/eni.json \
	.make/task/status.json
.INTERMEDIATE: \
	.make/task/eni.txt \
	.make/task/public_ip.txt \
	.make/task/public_dns.txt
.ALWAYS:

CLUSTER := valheim
CONTAINER := valheim

task/:; mkdir -p ${@}

task/svc_arn.txt: | task/
	@echo >&2 "> Checking for current service arn."
	aws ecs list-services --cluster "${CLUSTER}" \
		| jq -re '.serviceArns | first | select(length>0)' \
		> ${@}

task/arn.txt: .ALWAYS | task/
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

task/desc.json: task/arn.txt
	@echo >&2 "> Fetching task description."
	@desc="$$(aws ecs describe-tasks \
			--cluster "${CLUSTER}" \
			--tasks "$(file < ${<})" \
		| jq '.tasks | first | select(length>0)')"
	@if [ "$$(md5sum <<<"$${desc}")" != "$$(md5sum ${@})" ]; then \
		echo >&2 "> Task desc has changed."; \
		echo -n "$${desc}" > ${@}; \
	fi

task/eni.txt: task/desc.json
	@echo >&2 "> Extracting ENI attached to task."
	@cat "${<}" \
		| jq -re '.attachments[].details[] | select(.name=="networkInterfaceId") | .value' \
		> ${@}
task/eni.json: task/eni.txt
	@echo >&2 "> Fetching task ENI description."
	@aws ec2 describe-network-interfaces \
			--network-interface-ids "$(file < ${<})" \
		| jq -e '.NetworkInterfaces | first | select(length>0)' \
		> ${@}

task/public_ip.txt: task/eni.json
	@echo >&2 "> Extracting public IP."
	@cat "${<}" \
		| jq -er '.Association.PublicIp' \
		> ${@}
task/public_dns.txt: task/eni.json
	@echo >&2 "> Extracting public hostname."
	@cat "${<}" \
		| jq -er '.Association.PublicDnsName' \
		> ${@}

task/status.json: task/public_ip.txt .ALWAYS
	@echo >&2 "> Fetching server status."
	@curl -s "http://$(file < ${<})/status.json" \
		| jq \
		> ${@}

addr: task/public_ip.txt task/public_dns.txt
	@echo "$(file < $(word 1,${^}))"
	@echo "$(file < $(word 2,${^}))"

#: Outputs the current server status
status: task/status.json
	@cat ${<}

#: Connects to the running task
exec: task/arn.txt
	@aws ecs execute-command \
		--cluster "${CLUSTER}" \
		--task "$(file < ${<})" \
		--container "${CONTAINER}" \
		--command 'bash' \
		--interactive

test: task/public_ip.txt
	@echo >&2 "> Checking geekstrom api for Valheim response."
	@echo -e "2456: $$(curl -s "https://geekstrom.de/valheim/check/api.php?host=$(file < ${<})&port=2456")"
	@echo -e "2457: $$(curl -s "https://geekstrom.de/valheim/check/api.php?host=$(file < ${<})&port=2457")"

server-up: task/svc_arn.txt
	@aws ecs update-service \
			--cluster "${CLUSTER}" \
			--service "$(file < ${<})" \
			--desired-count 1 \
			--force-new-deployment \
		| jq '.service.deployments'

server-down: task/svc_arn.txt
	@aws ecs update-service \
			--cluster "${CLUSTER}" \
			--service "$(file < ${<})" \
			--desired-count 0 \
		| jq '.service.deployments'
