# This file is generated by the template.

REGISTRY?=cr.loongnix.cn
ORGANIZATION?=library
REPOSITORY?=loongnix
TAG?=20-slim

IMAGE=$(REGISTRY)/$(ORGANIZATION)/$(REPOSITORY):$(TAG)

ROOTFS=rootfs.tar.xz

default: image

image: $(ROOTFS)
	docker build \
		-t $(IMAGE) \
		.

push:
	docker push $(IMAGE)

$(ROOTFS):
	./make_rootfs.sh
