#!/usr/bin/env bash
set -eo pipefail

echo >&2 "Curl-ing status on port ${STATUS_HTTP_PORT}"
status="$(curl -sSL "http://localhost:${STATUS_HTTP_PORT}")"
echo -e >&2 "Curl output: >>>\n${status}\n<<<"

cat /opt/valheim/htdocs/status.json | jq
