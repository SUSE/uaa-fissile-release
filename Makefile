#!/usr/bin/env make
GIT_ROOT:=$(shell git rev-parse --show-toplevel)

build: certs releases images

certs:
	${GIT_ROOT}/generate-certs.sh

releases:
	${GIT_ROOT}/make/releases

images:
	${GIT_ROOT}/make/images

kube-configs kube/bosh/uaa.yml:
	${GIT_ROOT}/make/kube-configs

package-kube:
	${GIT_ROOT}/make/package-kube

publish:
	${GIT_ROOT}/make/publish

.PHONY: build certs releases images kube-configs package-kube publish


run: kube/bosh/uaa.yml
	${GIT_ROOT}/make/run

stop:
	${GIT_ROOT}/make/stop
