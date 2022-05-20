#!/usr/bin/env bash
set -eo pipefail

logfile=hooks-$(date +%y%m%d).log

echo "${0}: BACKUPS_DIR=${BACKUPS_DIR}" >> ${logfile}
echo "${0}: S3_URL_BAK=${S3_URL_BAK}" >> ${logfile}

echo "${0}: Starting backup." >> ${logfile}
aws s3 sync "${BACKUPS_DIR}" "${S3_URL_BAK}" \
	--storage-class ONEZONE_IA

echo "${0}: Backup complete." >> ${logfile}
