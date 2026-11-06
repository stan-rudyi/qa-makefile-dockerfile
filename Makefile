APP      ?= test_app
REGISTRY ?= quay.io/projectquay/golang
VERSION  ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
 
HOST_OS   := $(shell uname -s | tr '[:upper:]' '[:lower:]')
HOST_ARCH := $(shell uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')
 
TARGETOS   ?= $(HOST_OS)
TARGETARCH ?= $(HOST_ARCH)
IMAGE_TAG  = $(REGISTRY)/$(APP):$(VERSION)-$(TARGETOS)-$(TARGETARCH)

.PHONY: image linux arm macos windows clean

image:
	docker build --platform=$(TARGETOS)/$(TARGETARCH) -t $(IMAGE_TAG) .
 
linux:
	$(MAKE) image TARGETOS=linux TARGETARCH=amd64
 
arm:
	$(MAKE) image TARGETOS=linux TARGETARCH=arm64
 
macos:
	$(MAKE) image TARGETOS=darwin TARGETARCH=arm64
 
windows:
	$(MAKE) image TARGETOS=windows TARGETARCH=amd64
 
clean:
	docker rmi $(IMAGE_TAG)