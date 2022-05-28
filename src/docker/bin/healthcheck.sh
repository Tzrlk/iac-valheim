#!/usr/bin/env bash

echo >&2 "Curl-ing status on port ${STATUS_HTTP_PORT}"
status="$(
	curl -fsL "http://localhost:${STATUS_HTTP_PORT}/status.json" \
	|| cat /opt/valheim/htdocs/status.json
)"

error="$(echo "${status}" | jq -r '.error | select(. != null)')"
if [ -n "${error}" ]; then
	echo "${error}"
	exit 1
fi

echo "${status}"
