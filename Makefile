PWD := $(shell pwd)

.PHONY: init
init: install-prerequisites pki set-master-ssh-key-fingerprint-in-minion-config
	@echo 'Set git to ignore any changes made to $(PWD)/minion/conf/override.conf'
	git update-index --assume-unchanged $(PWD)/minion/conf/override.conf
	@echo 'Run the following command to set git to track changes in the file again'
	@echo '    git update-index --no-assume-unchanged $(PWD)/minion/conf/override.conf'
	@echo 'Set git to ignore any changes made to $(PWD)/docker-compose.yaml'
	git update-index --assume-unchanged $(PWD)/docker-compose.yaml
	@echo 'Run the following command to set git to track changes in the file again'
	@echo '    git update-index --no-assume-unchanged $(PWD)/docker-compose.yaml'

.PHONY: install-prerequisites
install-prerequisites:
	pipenv install

.PHONY: pki
pki: | $(PWD)/master/pki/master.pem $(PWD)/minion/pki/minion.pem

$(PWD)/master/pki:
	mkdir -p $(PWD)/master/pki

$(PWD)/master/pki/master.pem:
	cd $(PWD)/master/pki/ && pipenv run salt-key --gen-keys=master

$(PWD)/minion/pki:
	mkdir -p $(PWD)/minion/pki

$(PWD)/minion/pki/minion.pem:
	cd $(PWD)/minion/pki/ && pipenv run salt-key --gen-keys=minion

.PHONY: set-master-ssh-key-fingerprint-in-minion-config
set-master-ssh-key-fingerprint-in-minion-config: pki
	@{ \
		pyt=$$(pipenv --py) ; \
		fp=$$($${pyt} -c 'from salt import utils; print(utils.pem_finger(path="$(PWD)/master/pki/master.pub"))') ; \
		cp $(PWD)/minion/conf/override.conf $(PWD)/minion/conf/override.conf.bak ; \
		sed -i.bak '/^master_finger: /d' $(PWD)/minion/conf/override.conf ; \
		echo "master_finger: '$${fp}'" >> $(PWD)/minion/conf/override.conf ; \
	}

.PHONY: up
up:
	pipenv run docker-compose up -d

.PHONY: down
down:
	pipenv run docker-compose down

.PHONY: ps
ps:
	pipenv run docker-compose ps

.PHONY: exec-master
exec-master:
	pipenv run docker-compose exec master /bin/bash

.PHONY: exec-minion
exec-minion:
	pipenv run docker-compose exec minion /bin/bash

.PHONY: build
build:
	pipenv run docker-compose build

.PHONY: start
start:
	pipenv run docker-compose start

.PHONY: stop
stop:
	pipenv run docker-compose stop

.PHONY: clean
clean: down

.PHONY: destroy
destroy: clean
	rm -rf $(PWD)/master/pki
	rm -rf $(PWD)/minion/pki
	rm $(PWD)/minion/conf/*.bak*
	git update-index --no-assume-unchanged $(PWD)/minion/conf/override.conf
	git checkout $(PWD)/minion/conf/override.conf
	git update-index --no-assume-unchanged $(PWD)/docker-compose.yaml
	git checkout $(PWD)/docker-compose.yaml

# https://stackoverflow.com/a/26339924
# @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs
.PHONY: list
list:
	grep '\.PHONY' ./Makefile | awk '{print $$2}'
