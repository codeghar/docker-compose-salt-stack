FROM ubuntu:18.04

RUN    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
    && apt update \
    && apt install -y apt-transport-https bash curl gnupg2 python3 unzip vim zip \
    && curl -fsSL https://repo.saltstack.com/apt/ubuntu/18.04/amd64/latest/SALTSTACK-GPG-KEY.pub | apt-key add -

# https://repo.saltstack.com/#ubuntu
COPY saltstack.list /etc/apt/sources.list.d/saltstack.list

RUN    apt update \
    && apt install -y salt-master

EXPOSE 4505/tcp 4506/tcp
