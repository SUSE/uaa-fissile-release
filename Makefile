#!/usr/bin/env make

.PHONY: prep build compile images kube kube-dist helm publish run stop dist generate mysql-release uaa-release

########## VAGRANT VM TARGETS ##########

prep: \
	compile \
	images \
	${NULL}

run:
	make/run

stop:
	make/stop

upgrade:
	make/upgrade

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
