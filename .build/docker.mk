# docker targets for make

ROOT ?= ..
BUILD_DIR := ${ROOT}/.build
include ${BUILD_DIR}/config.mk

DOCKER_DIR := ${ROOT}/src/docker
DOCKER_IMAGE_NAME := tzrlk/valheim-server
DOCKER_IMAGE_TAG  := latest

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
		--tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} \
		${DOCKER_DIR}/

push: ${BUILD_DIR}/docker/pushed
${BUILD_DIR}/docker/pushed: \
		${BUILD_DIR}/docker/image
	docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}

# Logs-in to ECR
ecr:
	aws ecr get-login-password \
	| docker login \
			--username AWS \
			--password-stdin \
			${DOCKER_REGISTRY}
