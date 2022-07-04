# docker targets for make

ROOT ?= ..

DOCKER_DIR := ${ROOT}/src/docker
BUILD_dir  := ${ROOT}/.build

#: Triggers a build of the docker image if necessary.
docker: ${BUILD_DIR}/docker/image
${BUILD_DIR}/docker/image: \
		${DOCKER_DIR}/Dockerfile \
		${DOCKER_DIR}/.dockerignore \
		$(wildcard ${DOCKER_DIR}/*/*)
	docker build \
		--iid ${@} \
		--tag tzrlk/valheim-server:latest \
		${DOCKER_DIR}/

# Logs-in to ECR
ecr:
	aws ecr get-login-password \
	| docker login \
			--username AWS \
			--password-stdin \
			${DOCKER_REGISTRY}
