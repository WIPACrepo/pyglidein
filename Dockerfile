# A RHEL6 container running a pyglidein

FROM centos:6
MAINTAINER Claudio Kopper <kopper@ualberta.ca>
ENV TINI_VERSION v0.14.0

WORKDIR /root

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
RUN chmod +x /sbin/tini

RUN yum -y install git wget curl libtool-ltdl libgomp

RUN useradd --create-home --shell /bin/bash condor

RUN mkdir -p /home/condor/pyglidein
RUN curl -o /home/condor/pyglidein/glidein.tar.gz http://prod-exe.icecube.wisc.edu/glidein-RHEL_6_x86_64.tar.gz

COPY . /home/condor/pyglidein
RUN chown -R condor:condor /home/condor/pyglidein

USER condor
WORKDIR /home/condor/pyglidein

ENV SITE=dockerized_pyglidein \
    CPUS=1 \
    GPUS=0 \
    MEMORY=4000 \
    DISK=8000000 \
    WALLTIME=72000

ENTRYPOINT ["/sbin/tini", "-g", "--", "/home/condor/pyglidein/glidein_start.sh"]
