# Image: dnssec-bind
# Startup a docker container with sshd and named for attendees

FROM debian:latest

MAINTAINER dape16 "dockerhub@arminpech.de"

# Install software
RUN     apt-get update
RUN     apt-get purge -y exim4 rpcbind portmap at avahi-daemon
RUN     apt-get install -y openssh-server tcpdump traceroute curl git less screen vim ntp ntpdate bind9 libnet-dns-sec-perl
RUN     rm -rf /var/lib/apt/lists/*
RUN     apt-get clean

# Set login data
RUN     echo 'root:root' | chpasswd

# Configure sshd
RUN     sed -i 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN     sed -i 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN     sed -i '/UseDNS/id' /etc/ssh/sshd_config
RUN     echo 'UseDNS no' >>/etc/ssh/sshd_config

RUN     mkdir -p /var/run/sshd


# Prepare bind
RUN     rm -rf /etc/bind
RUN     mkdir -p /etc/bind/zones /etc/bind/keys /etc/bind/scripts
RUN     rndc-confgen | awk '/^key "rndc-key"/,/^};/ {print}' > /etc/bind/rndc.key

# Deploy DNSSEC workshop material
COPY    ../../shared/etc/bind/scripts/dnskey2ds.pl /etc/bind/scripts/
# TODO
	
EXPOSE  22
CMD     [ "/usr/sbin/sshd", "-D" ]

EXPOSE  53
CMD     /etc/init.d/bind9 start

# vim: set syntax=docker tabstop=2 expandtab:
