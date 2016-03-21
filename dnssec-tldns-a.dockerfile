# Image: dnssec-tldns-a
# Startup a docker container as BIND master for DNS TLDs

FROM dape16/dnssec-bind

MAINTAINER dape16 "dockerhub@arminpech.de"

# Set timezone
ENV     TZ=Europe/Berlin
RUN     ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Deploy DNSSEC workshop material
COPY    dnssec-tldns-a/ /

# Install software
RUN     apt-get update
RUN     apt-get upgrade -y
RUN     echo "mysql-server mysql-server/root_password password root" | debconf-set-selections
RUN     echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections
RUN     apt-get install -y --no-install-recommends apache2 mysql-server golang-go

# Configure webserver
RUN     a2dissite 000-default
RUN     a2ensite sld-registrar
RUN     a2enmod proxy proxy_http

# Start services using supervisor
RUN     mkdir -p /var/log/supervisor

EXPOSE  22 53 80
CMD     [ "/usr/bin/supervisord -c /etc/supervisor/conf.d/dnssec-tldns-a.conf" ]

# Setup dataabase for whois/registrar service
CMD     [ "mysql -uroot -proot -e 'create database sld charset utf8;'" ]
CMD     [ "mysql -uroot -proot sld < /etc/whoisd/sld.mysql" ]

# vim: set syntax=docker tabstop=2 expandtab:
