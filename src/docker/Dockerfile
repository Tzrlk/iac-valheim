# syntax=docker/dockerfile:1.4

FROM debian:buster-slim as aws-cli

# Install/update needed packages.
RUN --mount=type=cache,id=apt,target=/var/lib/apt/lists/,sharing=locked \
	apt-get update \
	&& apt-get install -y \
		curl \
		unzip

RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
		--output awscliv2.zip
RUN unzip awscliv2.zip

FROM ghcr.io/lloesche/valheim-server:latest

# Install/update needed packages.
RUN --mount=type=cache,id=apt,target=/var/lib/apt/lists/,sharing=locked \
	apt-get update \
	&& apt-get install -y \
		groff

# Install aws client for S3 access.
RUN --mount=type=bind,target=/aws/,source=/aws/,from=aws-cli \
	/aws/install
 
# Trigger valheim setup scripts.
# /usr/local/sbin/bootstrap
RUN --mount=type=cache,id=val,target=/opt/valheim/dl/server \
	env POST_UPDATE_CHECK_HOOK=shutdown \
		/usr/local/bin/valheim-updater

ARG HOOKS_DIR=/usr/local/share/valheim/contrib
ARG S3_URL

# Add S3 backup scripts.
ARG S3_URL_BAK=${S3_URL}/backups
ENV POST_BACKUP_HOOK=${HOOKS_DIR}/s3_backup.sh \
	BACKUPS_DIR=/config/backups
COPY --chmod=755 <<-EOF ${POST_BACKUP_HOOK}
	#!/usr/bin/env bash
	aws s3 sync "${BACKUPS_DIR}" "${S3_URL_BAK}" \\
			--storage-class ONEZONE_IA
EOF

ARG S3_URL_CFG=${S3_URL}/worlds
# Pull-down the last recorded world config
ENV PRE_BOOTSTRAP_HOOK=${HOOKS_DIR}/s3_load.sh \
	WORLDS_DIR=/config/worlds
COPY --chmod=755 --link <<-EOF ${PRE_BOOTSTRAP_HOOK}
	#!/usr/bin/env bash
	mkdir -p "${WORLDS_DIR}" \\
	&& aws s3 sync \\
			"${S3_URL_CFG}" \\
			"${WORLDS_DIR}"
EOF
# Upload the final state of the world before ending.
ENV POST_SHUTDOWN_HOOK=${HOOKS_DIR}/s3_save.sh
COPY --chmod=755 --link <<-EOF ${POST_SHUTDOWN_HOOK}
	#!/usr/bin/env bash
	aws s3 sync \\
			"${WORLDS_DIR}" \\
			"${S3_URL_CFG}"
EOF

COPY --chmod=755 --link <<-EOF /healthcheck.sh
	#!/usr/bin/env bash
	if status="$(curl -sSL http://localhost:\${STATUS_HTTP}/)"; then
		echo "\${status}" | jq -e && exit 0

	elif [ -f /opt/valheim/htdocs/status.json ]
		cat /opt/valheim/htdocs/status.json | jq -e

	else
		echo "No status information available!"
	fi
	exit 1
EOF

ENV UPDATE_CRON="@yearly"
