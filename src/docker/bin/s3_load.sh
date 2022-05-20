#!/usr/bin/env bash
set -eo pipefail

logfile=hooks-$(date +%y%m%d).log

echo "${0}: WORLDS_DIR=${WORLDS_DIR}" >> ${logfile}
echo "${0}: S3_URL_CFG=${S3_URL_CFG}" >> ${logfile}

if [ ! -d "${WORLDS_DIR}" ]; then
	echo "${0}: Worlds dir doesn't exist. Creating." >> ${logfile}
	mkdir -p "${WORLDS_DIR}"
fi

echo "${0}: Pulling-down the last recorded world config." >> ${logfile}
aws s3 sync \
	"${S3_URL_CFG}" \
	"${WORLDS_DIR}"

echo "${0}: Complete." >> ${logfile}