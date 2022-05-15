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
ENV POST_BACKUP_HOOK=${HOOKS_DIR}/s3_backup.sh
COPY <<EOF ${POST_BACKUP_HOOK}
	#!/usr/bin/env bash
	# $1 is backup file (/config/backups/worlds-33252352-32423.zip)
	aws s3 sync "$(dirname "\${1}")" "${S3_URL_BAK}" \\
			--storage-class ONEZONE_IA
EOF

ARG S3_URL_CFG=${S3_URL}/worlds
# Pull-down the last recorded world config
ENV PRE_BOOTSTRAP_HOOK=${HOOKS_DIR}/s3_load.sh
COPY --link <<EOF ${PRE_BOOTSTRAP_HOOK}
	#!/usr/bin/env bash
	mkdir -p /config/worlds \\
	&& aws s3 sync \\
			"${S3_URL_CFG}" \\
			/config/worlds/
EOF
# Upload the final state of the world before ending.
ENV POST_SHUTDOWN_HOOK=${HOOKS_DIR}/s3_save.sh
COPY --link <<EOF ${POST_SHUTDOWN_HOOK}
	#!/usr/bin/env bash
	aws s3 sync \\
			/config/worlds/ \\
			"${S3_URL_CFG}"
EOF

ENV UPDATE_CRON="@yearly"
