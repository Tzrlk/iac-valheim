#!/usr/bin/env bash
set -eo pipefail

logfile=hooks-$(date +%y%m%d).log

echo "${0}: WORLDS_DIR=${BACKUPS_DIR}" >> ${logfile}
echo "${0}: S3_URL_CFG=${S3_URL_BAK}" >> ${logfile}

echo "${0}: Starting save." >> ${logfile}
aws s3 sync \
	"${WORLDS_DIR}" \
	"${S3_URL_CFG}"

echo "${0}: Save complete." >> ${logfile}
