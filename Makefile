.PHONY: init
init: install-prerequisites

.PHONY: install-prerequisites
install-prerequisites:
	pipenv install

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

.PHONY: clean
clean: down

# https://stackoverflow.com/a/26339924
# @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs
.PHONY: list
list:
	grep '\.PHONY' ./Makefile | awk '{print $$2}'
