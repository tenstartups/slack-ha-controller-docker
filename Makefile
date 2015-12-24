DOCKER_IMAGE_NAME := tenstartups/slack-ha-controller
ifeq ($(DOCKER_ARCH),rpi)
	DOCKER_IMAGE_NAME := $(subst /,/$(DOCKER_ARCH)-,$(DOCKER_IMAGE_NAME))
endif

build: Dockerfile.$(DOCKER_ARCH)
	docker build --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME) .

clean_build: Dockerfile.$(DOCKER_ARCH)
	docker build --no-cache --file Dockerfile.$(DOCKER_ARCH) --tag $(DOCKER_IMAGE_NAME) .

run: build
	docker run -it --rm \
	-p 8080:8080 \
	-v /etc/localtime:/etc/localtime \
	-v $(PWD)/test:/etc/webhook \
	-e VIRTUAL_HOST=ha-slackhooks.docker \
	-e CONFIG_FILE=/etc/webhook/config.yml \
	--name ha-slackhooks \
	${DOCKER_IMAGE_NAME} ${ARGS}

push: build
	docker push ${DOCKER_IMAGE_NAME}:latest
