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

## ASSEMBLY ####################################################################
FROM ghcr.io/lloesche/valheim-server:latest as assembly

# Install aws client for S3 access.
RUN --mount=type=cache,id=apt,target=/var/lib/apt/lists/,sharing=locked \
    --mount=type=bind,from=aws-cli,source=/aws,target=/aws \
	apt-get update && apt-get install -y \
		groff \
	&& /aws/install \
	&& aws --version

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

# Tweak ip address config.
COPY --link \
	etc/no_ipv6.conf \
	/etc/sysctl.d/

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
