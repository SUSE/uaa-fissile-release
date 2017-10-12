#!/usr/bin/env make

.PHONY: build certs releases images kube kube-dist helm publish run stop dist generate

build: releases images

certs:
	./generate-certs.sh

releases:
	make/releases

images:
	make/images

kube:
	make/kube

kube-dist:
	make/kube-dist

helm:
	make/kube helm

publish:
	make/publish

run:
	make/run

stop:
	make/stop

dist: kube-dist

generate: kube
