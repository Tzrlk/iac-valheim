#!/usr/bin/env bash
set -eo pipefail

if [ -z "${S3_URL_CFG}" ]; then
	echo >&2 'S3_URL_CFG not set. Skipping S3 load.'
	exit 0
fi

echo >&2 "${0}: WORLDS_DIR=${WORLDS_DIR}"
echo >&2 "${0}: S3_URL_CFG=${S3_URL_CFG}"

if [ ! -d "${WORLDS_DIR}" ]; then
	echo >&2 "${0}: Worlds dir doesn't exist. Creating."
	mkdir -p "${WORLDS_DIR}"
fi

echo >&2 "${0}: Pulling-down the last recorded world config."
aws s3 sync \
	"${S3_URL_CFG}" \
	"${WORLDS_DIR}"

echo >&2 "${0}: Complete."
