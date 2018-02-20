#!/usr/bin/env make

.PHONY: prep build releases compile images kube kube-dist helm publish run stop dist generate mysql-release uaa-release uaa-helper-release

########## VAGRANT VM TARGETS ##########

prep: \
	releases \
	compile \
	images \
	${NULL}

run:
	make/run

stop:
	make/stop

upgrade:
	make/upgrade

########## BOSH RELEASE TARGETS ##########

mysql-release:
	RUBY_VERSION=2.3.1 make/bosh-release src/cf-mysql-release

uaa-release:
	make/bosh-release src/uaa-release

uaa-helper-release:
	make/bosh-release src/uaa-helper-release

releases: \
	mysql-release \
	uaa-release \
	uaa-helper-release \
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
