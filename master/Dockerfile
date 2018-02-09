FROM ubuntu:16.04

RUN    apt update \
    && apt install -y bash curl python3 unzip vim zip \
    && curl -fsSL https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub | apt-key add -

# https://repo.saltstack.com/#ubuntu
COPY saltstack.list /etc/apt/sources.list.d/saltstack.list

RUN    apt update \
    && apt install -y salt-master

CMD ["/sbin/init"]
