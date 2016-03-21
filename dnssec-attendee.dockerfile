# Image: dnssec-attendee
# Startup a docker container with sshd and named for attendees

FROM dape16/dnssec-bind

MAINTAINER dape16 "dockerhub@arminpech.de"

# Install software
RUN     echo "postfix postfix/mailname string dnssec-attendee" | debconf-set-selections
RUN     echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections

RUN     apt-get update
RUN     apt-get upgrade -y
RUN     apt-get install -y --no-install-recommends mailutils postfix nginx
RUN     rm -rf /var/lib/apt/lists/*
RUN     apt-get clean

# Deploy DNSSEC workshop material
COPY    dnssec-attendee/ /

# Set timezone
ENV     TZ=Europe/Berlin
RUN     ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Start services using supervisor
RUN     mkdir -p /var/log/supervisor

EXPOSE  22 25 53 80 443 465
CMD     [ "/usr/bin/supervisord -c /etc/supervisor/conf.d/dnssec-attendee.conf" ]

# vim: set syntax=docker tabstop=2 expandtab:
