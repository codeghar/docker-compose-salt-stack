PWD := $(shell pwd)

.PHONT: help
help:
	@echo make init
	@echo '    Install prerequisites'
	@echo '    Setup keys for master and minion'
	@echo make build
	@echo '    Build container images'
	@echo make up
	@echo '    Start containers'
	@echo '    Start Salt master'
	@echo '    Start Salt minion'
	@echo '    Accept all keys on Salt master'
	@echo make exec-master
	@echo '    Start interactive bash session in master container'
	@echo make exec-minion
	@echo '    Start interactive bash session in minion container'
	@echo make ubuntu-16.04
	@echo '    Modify Dockerfile and other related files to allow running Ubuntu 16.04 all around'
	@echo '    Then run `make build up` to start this new environment'
	@echo '    Run `make clean` to go back to Ubuntu 18.04 (overwrites any changes you may have made)'
	@echo make ubuntu-14.04
	@echo '    Modify Dockerfile and other related files to allow running Ubuntu 14.04 all around'
	@echo '    Then run `make build up` to start this new environment'
	@echo '    Run `make clean` to go back to Ubuntu 18.04 (overwrites any changes you may have made)'
	@echo make list
	@echo '    Show all make targets'

# https://stackoverflow.com/a/26339924
# @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs
.PHONY: list
list:
	@grep -E '^\.PHONY' ./Makefile | awk '{print $$2}'

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

$(PWD)/master/pki/master.pem: | $(PWD)/master/pki
	cd $(PWD)/master/pki/ && pipenv run salt-key --gen-keys=master

$(PWD)/minion/pki:
	mkdir -p $(PWD)/minion/pki

$(PWD)/minion/pki/minion.pem: | $(PWD)/minion/pki
	cd $(PWD)/minion/pki/ && pipenv run salt-key --gen-keys=minion

.PHONY: set-master-ssh-key-fingerprint-in-minion-config
set-master-ssh-key-fingerprint-in-minion-config: pki
	@{ \
		pyt=$$(pipenv --py) ; \
		fp=$$($${pyt} -c 'from salt.utils import crypt; print(crypt.pem_finger(path="master/pki/master.pub"))'); \
		cp $(PWD)/minion/conf/override.conf $(PWD)/minion/conf/override.conf.bak ; \
		sed -i.bak '/^master_finger: /d' $(PWD)/minion/conf/override.conf ; \
		echo "master_finger: '$${fp}'" >> $(PWD)/minion/conf/override.conf ; \
	}

.PHONY: up
up:
	pipenv run docker-compose up -d
	pipenv run docker-compose exec master service salt-master start
	sleep 15s
	pipenv run docker-compose exec minion service salt-minion start
	sleep 15s
	pipenv run docker-compose exec master salt-key --accept-all --yes

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
	pipenv run docker-compose exec master service salt-master start
	pipenv run docker-compose exec minion service salt-minion start

.PHONY: stop
stop:
	pipenv run docker-compose stop

.PHONY: clean
clean: down
	git checkout master/Dockerfile
	git checkout master/saltstack.list
	git checkout minion/Dockerfile
	git checkout minion/saltstack.list

.PHONY: destroy
destroy: clean
	rm -rf $(PWD)/master/pki
	rm -rf $(PWD)/minion/pki
	rm -f $(PWD)/minion/conf/*.bak*
	git update-index --no-assume-unchanged $(PWD)/minion/conf/override.conf
	git checkout $(PWD)/minion/conf/override.conf
	git update-index --no-assume-unchanged $(PWD)/docker-compose.yaml
	git checkout $(PWD)/docker-compose.yaml

.PHONY: ubuntu-14.04
ubuntu-14.04:
	git checkout master/Dockerfile
	git checkout master/saltstack.list
	git checkout minion/Dockerfile
	git checkout minion/saltstack.list
	git apply ubuntu-14.04.patch

.PHONY: ubuntu-16.04
ubuntu-16.04:
	git checkout master/Dockerfile
	git checkout master/saltstack.list
	git checkout minion/Dockerfile
	git checkout minion/saltstack.list
	git apply ubuntu-16.04.patch
