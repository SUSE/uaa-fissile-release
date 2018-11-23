#!/usr/bin/env make

.PHONY: prep build releases compile images kube kube-dist helm publish run stop dist generate mysql-release uaa-release scf-helper-release

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

scf-helper-release:
	cp container-host-files/etc/scf/config/role-manifest.yml src/scf-helper-release/src; \
	make/bosh-release src/scf-helper-release

releases: \
	scf-helper-release \
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
