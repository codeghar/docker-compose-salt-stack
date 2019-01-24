# Salt Stack with Docker Compose

Create a sandbox/playground with Docker Compose to learn Salt Stack, test your
config or ideas, etc.

# Requirements

* Docker
* Python 3.6+
* [pipenv](https://docs.pipenv.org/)
* GNU make
* Build tools like gcc, etc., for dependencies of Docker Compose and Salt
* grep
* git
* sed

# Initial Setup

        $ make init

1. Installs required Python packages using ``pipenv``.
2. Generates pki keys for master and minion. The keys are *not* replaced if they already exist in the right directories.
3. Modifies *./minion/conf/override.conf* to set the *master_finger* value based on the ssh keys generated in step 2.
4. Runs ``git update-index --assume-unchanged ./minion/conf/override.conf`` to ignore any changes made to the file. This is done because of the changes made in step 3. Manually revert this with ``git update-index --no-assume-unchanged ./minion/conf/override.conf``.
5. Runs ``git update-index --assume-unchanged ./docker-compose.yaml`` to ignore any changes made to the file as described in the Customize section. Manually revert this with ``git update-index --no-assume-unchanged ./docker-compose.yaml``.

# Environment Lifecycle

``docker-compose`` is used to manage the lifecycle of containers. Helper
targets in ``make`` are *up*, *down*, *start*, *stop*, and *ps* based on their
counterparts *up -d*, *down*, *start*, *stop*, and *ps* respectively in
``docker-compose``.

        $ make up
        $ make ps
        $ make stop
        $ make start
        $ make down

A helper target to build the master and minion Docker images is *build*. Since
it uses ``docker-compose``, the images will be built if needed.

        $ make build

Run ``bash`` in master container.

        $ make exec-master

Run ``bash`` in minion container.

        $ make exec-minion

Get a list of all ``make`` targets.

        $ make list

The *Makefile* is pretty simple; feel free to read it for more information.

## Caution

Cleaning up the environment is synonymous with *down*.

        $ make clean

## Alert

Destroying the environment rollsback changes made to the git repo in the *init*
target.

        $ make destroy

1. Deletes *pki* directories under *master* and *minion*.
2. Removes any .bak* files in *./minion/conf*.
3. Runs ``git update-index --no-assume-unchanged ./minion/conf/override.conf``.
4. Reverts *./minion/conf/override.conf* to the version in last commit.
5. Runs ``git update-index --no-assume-unchanged ./docker-compose.yaml``.
6. Reverts *./docker-compose.yaml* to the version in last commit.

# Customize

These files are prime candidates to customize for your needs.

## docker-compose.yml

Add volume(s) to the master container that contain the Salt config. Map it to
*/srv/salt* in the container,

        volumes:
            - *Other mappings already present*
            - /path/to/salt/config:/srv/salt:ro

## Makefile

The targets to create pki keys for master and minion are
*$(PWD)/master/pki/master.pem* and *$(PWD)/minion/pki/minion.pem*. They are
called as part of the *init* target. The reason both use the pattern of
changing directory and generating the key because of ``salt-key``
[behavior](https://groups.google.com/forum/#!topic/salt-users/GXTbkz5GZQU). If
the behavior changes in future, this workaround pattern may not be necessary.

The *set-master-ssh-key-fingerprint-in-minion-config* target uses a Python
command snippet which imports Salt and runs the ``pem_finger`` function.
The import path will change between Salt versions 2017.7.3 and 2018.1. Fix the
import path when needed.

## master/Dockerfile

Contains example for Ubuntu 18.04.

## master/saltstack.list

Configures a deb repo to always track latest release. Modify it to track a
specific version. Modify *./master/Dockerfile* as well to synchronize changes.
More information at https://repo.saltstack.com/#ubuntu.

## minion/Dockerfile

Contains example for Ubuntu 18.04.

## minion/saltstack.list

Configures a deb repo to always track latest release. Modify it to track a
specific version. Modify *./minion/Dockerfile* as well to synchronize changes.
More information at https://repo.saltstack.com/#ubuntu.

## minion/conf/override.conf

When you're using ``make init``, this step becomes unnecessary. The reason is
that our own generated keys are mounted in the master container. The *init*
target takes care of getting the fingerprint and modifying the minion config.

After the master is up, get its public key fingerprint.

        $ make exec-master
        # salt-key -F master

Replace *CHANGEME* for the key *master_finger* in *./minion/conf/override.conf*
file with the value of the public key finger print.

If you have not already started *salt-minion* service on the minion then start
it. Otherwise, restart it.

        $ make exec-minion
        # service salt-minion start

# Notes

## Minion

Minion may not start when the container is started. User may have to start it
manually,

        $ make exec-minion
        # service salt-minion start

## Try Other Ubuntu Versions

Instead of Ubuntu 18.04 you can use Ubuntu 16.04 or Ubuntu 14.04, like so,

    $ make ubuntu-16.04 build up
    $ make ubuntu-14.04 build up

Go back to Ubuntu 18.04,

    $ make clean
