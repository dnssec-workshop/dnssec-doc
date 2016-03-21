# Image: dnssec-tldns-a
# Startup a docker container as BIND slave for DNS TLDs

FROM dape16/dnssec-tldns-b

MAINTAINER dape16 "dockerhub@arminpech.de"

# Set timezone
ENV     TZ=Europe/Berlin
RUN     ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Deploy DNSSEC workshop material
COPY    dnssec-tldns-b/ /

# Start services using supervisor
RUN     mkdir -p /var/log/supervisor

EXPOSE  22 53
CMD     [ "/usr/bin/supervisord -c /etc/supervisor/conf.d/dnssec-bind.conf" ]

# vim: set syntax=docker tabstop=2 expandtab:
