#!/usr/bin/env bash
set -eo pipefail

if [ -z "${S3_URL_CFG}" ]; then
	echo >&2 'S3_URL_CFG not set. Skipping S3 load.'
	exit 0
fi

echo >&2 "${0}: WORLDS_DIR=${BACKUPS_DIR}"
echo >&2 "${0}: S3_URL_CFG=${S3_URL_CFG}"

echo >&2 "${0}: Starting save."
aws s3 sync \
	"${WORLDS_DIR}" \
	"${S3_URL_CFG}"

echo >&2 "${0}: Save complete."
