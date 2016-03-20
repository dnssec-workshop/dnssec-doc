# Image: dnssec-rootns-b
# Startup a docker container as BIND slave for DNS root zone

FROM dape16/dnssec-bind

MAINTAINER dape16 "dockerhub@arminpech.de"

# Deploy DNSSEC workshop material
COPY    dnssec-rootns-b/ /

# Set timezone
ENV     TZ=Europe/Berlin
RUN     ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Restart bind to load overwritten settings
RUN     /etc/init.d/bind9 restart

# vim: set syntax=docker tabstop=2 expandtab:
