# Image: dnssec-bind
# Startup a docker container with sshd and BIND 9.10

FROM ubuntu:wily

MAINTAINER dape16 "dockerhub@arminpech.de"

# Install software
RUN     echo "deb http://ppa.launchpad.net/mgrocock/bind9/ubuntu wily main" > /etc/apt/sources.list.d/wily-bind9.list
RUN     apt-key adv --keyserver pgp.mit.edu --recv-keys DC682B55
RUN     apt-get update
RUN     apt-get purge -y exim4 rpcbind portmap at avahi-daemon
RUN     apt-get upgrade -y
RUN     apt-get install -y --no-install-recommends tcpdump traceroute curl wget git less screen vim nano ntp ntpdate telnet syslog-ng zip unzip man
RUN     apt-get install -y --no-install-recommends openssh-server supervisor cron
RUN     apt-get install -y --no-install-recommends bind9 dnsutils libnet-dns-sec-perl whois openssl ldnsutils
RUN     rm -rf /var/lib/apt/lists/*
RUN     apt-get clean

# Set login data
RUN     echo 'root:root' | chpasswd

# Configure sshd
RUN     rm /etc/ssh/ssh_host_*
RUN     ssh-keygen -A
RUN     chmod 600 /etc/ssh/ssh_host_*

RUN     mkdir -p /var/run/sshd

# Prepare bind
RUN     rm -rf /etc/bind
RUN     mkdir -p /etc/bind/zones /etc/bind/keys /etc/bind/scripts
RUN     mkdir -p /var/log/named /var/run/named /var/lib/bind /var/cache/bind
RUN     chown -R root:bind /var/log/named /var/run/named /var/lib/bind /var/cache/bind /etc/bind/zones
RUN     chmod 775 /var/log/named /var/lib/bind /var/cache/bind /etc/bind/zones

RUN     rndc-confgen | awk '/^key "rndc-key"/,/^};/ {print}' > /etc/bind/rndc.key

# vim: set syntax=docker tabstop=2 expandtab:
