PWD := $(shell pwd)

.PHONY: init
init: install-prerequisites ssh-keys set-master-ssh-key-fingerprint-in-minion-config
	@echo 'Set git to ignore any changes made to $(PWD)/minion/conf/override.conf'
	git update-index --assume-unchanged $(PWD)/minion/conf/override.conf
	@echo 'Run the following command to set git to track changes in the file again'
	@echo '    git update-index --no-assume-unchanged $(PWD)/minion/conf/override.conf'

.PHONY: install-prerequisites
install-prerequisites:
	pipenv install

.PHONY: ssh-keys
ssh-keys: | $(PWD)/master/pki/master.pem $(PWD)/minion/pki/minion.pem

$(PWD)/master/pki:
	mkdir -p $(PWD)/master/pki

$(PWD)/master/pki/master: | $(PWD)/master/pki
	ssh-keygen -t rsa -b 4096 -f $(PWD)/master/pki/master -N ''

$(PWD)/master/pki/master.pem: | $(PWD)/master/pki/master
	cp $(PWD)/master/pki/master $(PWD)/master/pki/master.pem
	# ssh-keygen -f $(PWD)/master/pki/master -m PEM -e > $(PWD)/master/pki/master.pem

$(PWD)/minion/pki:
	mkdir -p $(PWD)/minion/pki

$(PWD)/minion/pki/minion: | $(PWD)/minion/pki
	ssh-keygen -t rsa -b 4096 -f $(PWD)/minion/pki/minion -N ''

$(PWD)/minion/pki/minion.pem: | $(PWD)/minion/pki/minion
	cp $(PWD)/minion/pki/minion $(PWD)/minion/pki/minion.pem

.PHONY: set-master-ssh-key-fingerprint-in-minion-config
set-master-ssh-key-fingerprint-in-minion-config: ssh-keys
	@{ \
		fp=$$(ssh-keygen -l -E md5 -f $(PWD)/master/pki/master.pem | awk '{print $$2}' | sed 's/^MD5://g') ; \
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

# https://stackoverflow.com/a/26339924
# @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs
.PHONY: list
list:
	grep '\.PHONY' ./Makefile | awk '{print $$2}'
