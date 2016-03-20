# Image: dnssec-attendee
# Startup a docker container with sshd and named for attendees

FROM dape16/dnssec-bind:latest

MAINTAINER dape16 "dockerhub@arminpech.de"

# Install software
RUN     echo "postfix postfix/mailname string dnssec-attendee" | debconf-set-selections
RUN     echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
RUN     apt-get update
RUN     apt-get install -y --no-install-recommends mailutils postfix nginx
RUN     rm -rf /var/lib/apt/lists/*
RUN     apt-get clean

# Deploy DNSSEC workshop material
COPY    shared/etc/trusted-key.key /etc/trusted-key.key
COPY    shared/etc/trusted-key.key /etc/unbound/root.key

COPY    dnssec-attendee/
COPY    dnssec-attendee/etc/bind/named.conf /etc/bind/named.conf
COPY    dnssec-attendee/etc/bind/zones/template.zone /etc/bind/zones/template.zone

COPY    shared/etc/bind/managed.keys /etc/bind/managed.keys
COPY    shared/etc/bind/zones/hint.zone /etc/bind/zones/hint.zone
COPY    shared/etc/bind/scripts/dnskey2ds.pl /etc/bind/scripts/dnskey2ds.pl
COPY    shared/etc/bind/scripts/sign-zone.sh /etc/bind/scripts/sign-zone.sh
COPY    shared/etc/bind/scripts/dnstouch.sh /etc/bind/scripts/dnstouch.sh
RUN     chmod 755 /etc/bind/scripts/*

# Postfix config
COPY    dnssec-attendee/etc/postfix/main.cf /etc/postfix/main.cf
COPY    dnssec-attendee/etc/postfix/master.cf /etc/postfix/master.cf

# Set timezone
ENV     TZ=Europe/Berlin
RUN     ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Start services using supervisor
RUN     mkdir -p /var/log/supervisor
COPY    dnssec-attendee/etc/supervisor/conf.d/dnssec-attendee.conf /etc/supervisor/conf.d/dnssec-attendee.conf

EXPOSE  22 25 53 465
CMD     [ "/usr/bin/supervisord -c /etc/supervisor/conf.d/dnssec-attendee.conf" ]

# vim: set syntax=docker tabstop=2 expandtab:
