# docker targets for make

ROOT ?= ..
BUILD_DIR := ${ROOT}/.build
include ${BUILD_DIR}/config.mk

DOCKER_DIR := ${ROOT}/src/docker

${BUILD_DIR}/docker/:
	mkdir -p ${@}

#: Triggers a build of the docker image if necessary.
docker: ${BUILD_DIR}/docker/image
${BUILD_DIR}/docker/image: \
		${DOCKER_DIR}/Dockerfile \
		${DOCKER_DIR}/.dockerignore \
		$(wildcard ${DOCKER_DIR}/*/*) \
		| ${BUILD_DIR}/docker/
	docker build \
		--iidfile ${@} \
		--build-arg S3_URL=${VH_S3_URL} \
		--tag tzrlk/valheim-server:latest \
		${DOCKER_DIR}/

# Logs-in to ECR
ecr:
	aws ecr get-login-password \
	| docker login \
			--username AWS \
			--password-stdin \
			${DOCKER_REGISTRY}
