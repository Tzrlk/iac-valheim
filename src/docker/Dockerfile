# syntax=docker/dockerfile:1.4

## AWS CLI #####################################################################
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

RUN /aws/install

## SERVER DATA #################################################################
FROM ghcr.io/lloesche/valheim-server:latest as server-data

# Bootstrap supervisord to speed things up.
RUN \
	PRE_SUPERVISOR_HOOK="exit 0" \
		/usr/local/sbin/bootstrap

# One-off valheim update download
ARG DATE
RUN \
	echo "Running update check for ${DATE}"; \
	POST_UPDATE_CHECK_HOOK=shutdown \
		/usr/local/bin/valheim-updater

## ASSEMBLY ####################################################################
FROM ghcr.io/lloesche/valheim-server:latest as assembly

# Install aws client for S3 access.
COPY --link --from=aws-cli \
	/usr/local/aws-cli \
	/usr/local/
COPY --link --from=aws-cli \
	/usr/local/bin/aws \
	/usr/local/bin/aws_completer \
	/usr/local/bin/

# Copy server data across.
COPY --link --from=server-data \
	/opt/steamcmd \
	/opt/valheim \
	/opt/
COPY --link --from=server-data \
	/root/.steam \
	/root/Steam \
	/root/

# Define and copy hook scripts
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

# Copy and define health check script
COPY --chmod=755 --link \
	bin/healthcheck.sh \
	/
HEALTHCHECK --start-period=120s \
	CMD /healthcheck.sh

# Define storage dirs
ENV \
	BACKUPS_DIR=/config/backups \
	WORLDS_DIR=/config/worlds

# Define S3 locations
ARG S3_URL
ENV \
	S3_URL_BAK=${S3_URL}/backups \
	S3_URL_CFG=${S3_URL}/worlds

# Define additional options
ENV \
	UPDATE_CRON="@yearly" \
	STATUS_HTTP="true" \
	STATUS_HTTP_PORT="8080"
