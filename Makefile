#!/usr/bin/env make
GIT_ROOT:=$(shell git rev-parse --show-toplevel)

build: certs releases images

certs:
	${GIT_ROOT}/generate-certs.sh

releases:
	${GIT_ROOT}/make/releases

images:
	${GIT_ROOT}/make/images

kube-configs:
	${GIT_ROOT}/make/kube-configs

.PHONY: build certs releases images kube-configs

