#!/usr/bin/env bash
set -eo pipefail

command="${*:-"bash"}"

vh='valheim'

task="$(aws ecs list-tasks --cluster "${vh}" \
	| jq -r '.taskArns | first | select(length>0)')"
if [ -z "${task}" ]; then
	echo >&2 "Nope."
	exit 1
fi

echo >&2 "Attempting to exec into ${task}/${vh} with ${command}"
aws ecs execute-command \
	--cluster "${vh}" \
	--task "${task}" \
	--container "${vh}" \
	--command "${command}" \
	--interactive
