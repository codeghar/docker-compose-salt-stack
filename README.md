# Salt Stack with Docker Compose

Create a sandbox/playground with Docker Compose to learn Salt Stack, test your
config or ideas, etc.

# Requirements

* Docker
* Python 3.6+
* [pipenv](https://docs.pipenv.org/)
* GNU make

# Initial Setup

        $ make init

# Environment Lifecycle

``docker-compose`` is used to manage the lifecycle of containers. Helper
targets in ``make`` are *up*, *down*, and *ps* based on their counterparts
*up -d*, *down*, and *ps* respectively in ``docker-compose``.

        $ make up
        $ make ps
        $ make down

A helper target to build the master and minion Docker images is *build*.

        $ make build

Run ``bash`` in master container.

        $ make exec-master

Run ``bash`` in minion container.

        $ make exec-minion

Get a list of all ``make`` targets.

        $ make list

## Caution

Cleaning up the environment is synonymous with *down*.

        $ make clean

# Customize

These files are prime candidates to customize for your needs.

## docker-compose.yml

May not require too much attention but you never know.

## Makefile

May not require too much attention but you never know.

## master/Dockerfile

Contains example for Ubuntu 16.04.

## master/saltstack.list

Configures the repo to always track latest release. Modify it to track a
specific version. Modify *master/Dockerfile* as well to synchronize changes.
More information at https://repo.saltstack.com/#ubuntu.

## minion/Dockerfile

Contains example for Ubuntu 14.04.

## minion/saltstack.list

Configures the repo to always track latest release. Modify it to track a
specific version. Modify *minion/Dockerfile* as well to synchronize changes.
More information at https://repo.saltstack.com/#ubuntu.
