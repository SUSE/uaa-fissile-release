#!/usr/bin/env make

build: releases images

certs:
	generate-certs.sh

releases:
	make/releases

images:
	make/images

kube kube/bosh/uaa.yaml: certs
	make/kube

kube-dist:
	make/kube-dist

helm: certs
	make/kube helm

publish:
	make/publish

.PHONY: build certs releases images kube kube-dist helm publish


run:
	make/run

stop:
	make/stop

dist: kube-dist

generate: kube
