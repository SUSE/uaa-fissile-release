#!/usr/bin/env make
ifeq ($(GIT_ROOT),)
GIT_ROOT:=$(shell git rev-parse --show-toplevel)
endif

build: certs releases images

certs:
	${GIT_ROOT}/generate-certs.sh

releases:
	${GIT_ROOT}/make/releases

images:
	${GIT_ROOT}/make/images

kube kube/bosh/uaa.yaml:
	${GIT_ROOT}/make/kube

kube-dist:
	${GIT_ROOT}/make/kube-dist

helm:
	${GIT_ROOT}/make/kube helm

publish:
	${GIT_ROOT}/make/publish

.PHONY: build certs releases images kube kube-dist helm publish


run: kube/bosh/uaa.yaml
	${GIT_ROOT}/make/run

stop:
	${GIT_ROOT}/make/stop

dist: kube-dist

generate: kube

