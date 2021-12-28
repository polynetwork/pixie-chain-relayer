APP_NAME:=relayer
HUB:=$(if $(HUB),$(HUB),your_docker_image_repo)
OS:=linux
ARCH:=$(shell go env GOARCH)
GO_VER=1.17.5
ALPINE_VER:=3.15.0

PRJ_DIR:=$(shell pwd -L)
GIT_BR:=$(shell git -C "${PRJ_DIR}" rev-parse --abbrev-ref HEAD | grep -v HEAD || git describe --tags || git -C "${PRJ_DIR}" rev-parse --short HEAD)
GIT_ID:=$(if $(CI_COMMIT_SHORT_SHA),$(CI_COMMIT_SHORT_SHA),$(shell git rev-parse --short HEAD))
GIT_DIR:=$(shell pwd -L|xargs basename)
BUILD_DIR:=$(PRJ_DIR)/build
APP_DIR:=$(BUILD_DIR)
BUILD_GOPATH=$(GOPATH)

TIMESTAMP := $(shell date -u '+%Y%m%d')
VER1 := $(if $(CI_COMMIT_TAG),$(CI_COMMIT_TAG).$(GIT_ID),$(if $(CI_COMMIT_SHORT_SHA),$(CI_COMMIT_SHORT_SHA),$(GIT_BR).$(GIT_ID)))
VER := $(if $(CI_Daily_Build),$(VER1).$(TIMESTAMP),$(VER1))

CGO_FLAGS=
GO_LD_FLAGS=

DOCKER_FILE=Dockerfile

.PHONY: build-prepare build docker

all: docker

build-prepare:
	@echo "[MAKEFILE] Prepare for building..."
	mkdir -p $(APP_DIR)/conf
	mkdir -p $(APP_DIR)/db
	mkdir -p $(APP_DIR)/keystore

build: build-prepare
	@echo "[MAKEFILE] Building binary for $(OS)/$(ARCH)"
	@go version
	$(CGO_FLAGS) GOOS=$(OS) GOARCH=$(ARCH) go build -o $(APP_DIR)/$(APP_NAME) $(PRJ_DIR)/main.go

docker:
	@echo "[MAKEFILE] Building docker image..."
	docker build --force-rm -f $(DOCKER_FILE) --build-arg GO_VER=$(GO_VER) --build-arg ALPINE_VER=$(ALPINE_VER) -t $(APP_NAME):$(VER) .

cloud: docker
	@echo "[MAKEFILE] Pushing docker image..."
	docker tag $(APP_NAME):$(VER) $(HUB)/$(APP_NAME):$(VER)
	docker push $(HUB)/$(APP_NAME):$(VER)
	@echo "[MAKEFILE] Done"

clean:
	@echo "[MAKEFILE] Clean builds..."
	rm ./build/* -rf
	@echo "[MAKEFILE] Done"