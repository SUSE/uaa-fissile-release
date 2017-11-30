#!/usr/bin/env make

.PHONY: build certs releases compile images kube kube-dist helm publish run stop dist generate

########## VAGRANT VM TARGETS ##########

prep: \
	certs \
	releases \
	compile \
	images \
	${NULL}

certs:
	./generate-certs.sh

run:
	make/run

stop:
	make/stop

########## BOSH RELEASE TARGETS ##########

mysql-release:
	RUBY_VERSION=2.3.1 make/bosh-release src/cf-mysql-release

uaa-release:
	make/bosh-release src/uaa-release

hcf-release:
	make/bosh-release src/hcf-release

releases: \
	mysql-release \
	uaa-release \
	hcf-release \
	${NULL}

########## FISSILE BUILD TARGETS ##########

compile:
	make/compile

images:
	make/images

build: compile images

publish:
	make/publish

########## KUBERNETES TARGETS ##########

kube:
	make/kube

helm:
	make/kube helm

########## CONFIGURATION TARGETS ##########

generate: kube

########## DISTRIBUTION TARGETS ##########

kube-dist:
	make/kube-dist

dist: kube-dist
