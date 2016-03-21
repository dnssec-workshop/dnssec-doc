# Image: dnssec-resolver
# Startup a docker container as resolver using BIND

FROM dape16/dnssec-bind

MAINTAINER dape16 "dockerhub@arminpech.de"

# Set timezone
ENV     TZ=Europe/Berlin
RUN     ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Deploy DNSSEC workshop material
COPY    dnssec-resolver/ /

# Install software
RUN     apt-get update
RUN     apt-get upgrade -y
## Install tools for DNSViz
RUN     apt-get install -y --no-install-recommends make python-dnspython python-pygraphviz
## Install libs and tools for m2crypto patch + compile
RUN     apt-get install -y --no-install-recommends swig libssl-dev gcc python-dev patch

## Install further tools
RUN     apt-get install -y --no-install-recommends gitweb

## Setup apache webderver
RUN     apt-get install -y --no-install-recommends apache
RUN     a2enmod cgid
RUN     a2dissite 000-default
RUN     mkdir /var/log/apache2/mod_cgi && chown www-data: /var/log/apache2/mod_cgi
RUN     mkdir /var/cache/git && chown www-data: /var/cache/git
RUN     a2ensite dnsviz.test gitweb.test doc.test

# Build DNSViz
RUN     cd /opt && git clone https://github.com/dnsviz/dnsviz \
          cd dnsviz && git checkout v0.5.1 \
          python setup.py build && python setup.py install

# Compile ECDSA into m2crypto
RUN     cd /opt && git clone https://gitlab.com/m2crypto/m2crypto.git \
          cd m2crypto && git chekout 0.23.0 \
          patch -p1 < /opt/dnsviz/contrib/m2crypto-0.23.patch \
          python setup.py build && python setup.py install

# Start services using supervisor
RUN     mkdir -p /var/log/supervisor

EXPOSE  22 53
CMD     [ "/usr/bin/supervisord -c /etc/supervisor/conf.d/dnssec-resolver.conf" ]

# vim: set syntax=docker tabstop=2 expandtab:
