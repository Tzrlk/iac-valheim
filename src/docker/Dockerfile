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

ENV \
	BACKUPS_DIR=/config/backups \
	WORLDS_DIR=/config/worlds

ARG S3_URL
ENV \
	S3_URL_BAK=${S3_URL}/backups \
	S3_URL_CFG=${S3_URL}/worlds

ARG HOOKS_DIR=/usr/local/share/valheim/contrib
ENV \
	POST_BACKUP_HOOK=${HOOKS_DIR}/s3_backup.sh \
	PRE_BOOTSTRAP_HOOK=${HOOKS_DIR}/s3_load.sh \
	POST_SHUTDOWN_HOOK=${HOOKS_DIR}/s3_save.sh

COPY --chmod=755 --link \
	bin/s3_backup.sh \
	bin/s3_load.sh \
	bin/s3_save.sh \
	${HOOKS_DIR}/

COPY --chmod=755 --link \
	bin/healthcheck.sh \
	/
HEALTHCHECK --start-period=120s \
	CMD /healthcheck.sh

ENV \
	UPDATE_CRON="@yearly" \
	STATUS_HTTP="true"
