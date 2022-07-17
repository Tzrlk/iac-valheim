#!/usr/bin/env bash
set -eo pipefail

if [ -z "${S3_URL_BAK}" ]; then
	echo >&2 'S3_URL_BAK not set. Skipping S3 backup.'
	exit 0
fi

echo >&2 "${0}: BACKUPS_DIR=${BACKUPS_DIR}"
echo >&2 "${0}: S3_URL_BAK=${S3_URL_BAK}"

echo >&2 "${0}: Starting backup."
aws s3 sync "${BACKUPS_DIR}" "${S3_URL_BAK}" \
	--storage-class ONEZONE_IA

echo >&2 "${0}: Backup complete."
