FROM ubuntu:15.10

ENV DEBCONF_FRONTEND noninteractive

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# TODO: software-properties-common is a HUGE dependency!
RUN apt-get update && apt-get install -y \
  apt-utils \
  apt-transport-https \
  software-properties-common

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv 68576280
RUN apt-add-repository -y "deb https://deb.nodesource.com/node_5.x wily main"

RUN apt-get update && apt-get install -y \
  bzip2 \
  nodejs \
  libfreetype6 \
  libfontconfig1

RUN apt-get purge -y \
  apt-utils \
  apt-transport-https \
  software-properties-common \
  && apt-get autoremove -y \
&& rm -rf /var/lib/apt/lists/*

RUN npm install -g phantomjs-prebuilt mermaid
