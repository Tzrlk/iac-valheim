# docker targets for make

docker: \
	src/docker/Dockerfile
	docker build \
		--tag tzrlk/valheim-server:latest \
		src/docker/

ecr:
	aws ecr get-login-password \
	| docker login \
			--username AWS \
			--password-stdin \
			${DOCKER_REGISTRY}
