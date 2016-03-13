# Image: dnssec-bind
# Startup a docker container with sshd and named for attendees

FROM debian:latest

MAINTAINER dape16 "dockerhub@arminpech.de"

# Install software
RUN     apt-get update
RUN     apt-get purge -y exim4 rpcbind portmap at avahi-daemon
RUN     apt-get upgrade -y
RUN     apt-get install -y --no-install-recommends openssh-server tcpdump traceroute curl git less screen vim ntp ntpdate bind9 dnsutils libnet-dns-sec-perl supervisor
RUN     rm -rf /var/lib/apt/lists/*
RUN     apt-get clean

# Set login data
RUN     echo 'root:root' | chpasswd

# Configure sshd
RUN     sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN     sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN     sed -ri '/UseDNS/id' /etc/ssh/sshd_config
RUN     echo 'UseDNS no' >>/etc/ssh/sshd_config

RUN     mkdir -p /var/run/sshd

# Prepare bind
RUN     rm -rf /etc/bind
RUN     mkdir -p /etc/bind/zones /etc/bind/keys /etc/bind/scripts
RUN     mkdir -p /var/log/named /var/lib/bind /var/cache/bind
RUN     chown -R root:bind /var/log/named /var/lib/bind /var/cache/bind
RUN     chmod 775 /var/log/named /var/lib/bind /var/cache/bind

RUN     rndc-confgen | awk '/^key "rndc-key"/,/^};/ {print}' > /etc/bind/rndc.key

# Deploy DNSSEC workshop material
COPY    dnssec-attendee/etc/bind/named.conf /etc/bind/named.conf
COPY    dnssec-attendee/etc/bind/zones/template.zone /etc/bind/zones/domain1.tld.zone
COPY    dnssec-attendee/etc/bind/zones/template.zone /etc/bind/zones/domain2.tld.zone

COPY    shared/etc/bind/managed.keys /etc/bind/managed.keys
COPY    shared/etc/bind/zones/hint.zone /etc/bind/zones/hint.zone
COPY    shared/etc/bind/scripts/dnskey2ds.pl /etc/bind/scripts/dnskey2ds.pl
COPY    shared/etc/bind/scripts/sign-zone.sh /etc/bind/scripts/sign-zone.sh
COPY    shared/etc/bind/scripts/dnstouch.sh /etc/bind/scripts/dnstouch.sh

# Set timezone
ENV     TZ=Europe/Berlin
RUN     ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Start services using supervisor
RUN     mkdir -p /var/log/supervisor
COPY    dnssec-attendee/etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE  22 53
CMD     [ "/usr/bin/supervisord" ]

# vim: set syntax=docker tabstop=2 expandtab:
