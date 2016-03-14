# Workshop Setup

Für Informationen zur Workshop-Umgebung siehe (/doc/workshop-environment.md)

Alle im folgenden verwendeten Commands werden zur Vereinfachung unter dem User root ausgeführt.

## Vorbreitungen der Umgebung

### Setup virtueller Maschinen für die DNS-Infrastruktur

Es werden VMs mit verschiedenen Funktionen/Rollen für die Bereitstellung einer DNS-Infrastruktur als Workshop-Umgebung eingerichtet.

1. Grundinstallation
   * Debian 8 mit Basissystem

   * Default Route via KVM-Wirt in Netzwerkkonfiguration setzen
        ```
        route add -net default gw 10.20.0.1
        ```

   * Software Setup
        ```
        apt-get purge exim4 rpcbind portmap at avahi-daemon
        apt-get install nmap tcpdump traceroute chkconfig curl git less screen bsd-mailx vim ntp ntpdate
        apt-get install bind9 libnet-dns-sec-perl
        ```

1. Installation spezifischer Software auf den VMs
   * dnssec-tldns: whois + Domain Registrar Service
        ```
        apt-get install apache2 mysql-server golang-go
        ```

   * dnssec-resolver: DNSSEC debugging Service
        ```
        apt-get install make python-pydot python-dnspython python-pygraphviz python-m2crypto
        apt-get install apache2 libapache2-mod-wsgi python-django postgresql-9.4 python-psycopg2
        ```


### Software-Konfiguration der Nameserver VMs

#### Konfiguration der Nameserver-Instanzen
1. Konfiguration der Master Nameserver
    siehe (dnssec-instancename/)

1. Git-Repository laden und Konfigurationen übertragen
    ```
    cd /root
    git clone https://github.com/pecharmin/dnssec-workshop.git
    rsync -av dnssec-workshop/$HOSTNAME/ /
    ```

1. Bei Bedarf kann die Systemkonfiguration aus dem Github Repo aktualisiert/überschrieben werden
    ```
    gup
    ```


1. Einrichtung der Software-Komponenten auf den Nameserver VMs
   * dnssec-rootns
     * Einrichtung des Master Nameservers inkl. Key Files für Zonen
        ```
        KEY_DIR=/etc/bind/keys
        mkdir $KEY_DIR

        for tld in "" test # Root und test. Zone
        do
          dnssec-keygen -K $KEY_DIR -n ZONE -3 -f KSK -a RSASHA256 -b 2048 -r /dev/urandom -L 2400 -P now -A now ${tld}.
          dnssec-keygen -K $KEY_DIR -n ZONE -3 -a RSASHA256 -b 1024 -r /dev/urandom -L 2400 -P now -A now ${tld}.
        done
        ```

   * dnssec-tldns
     * MySQL-Datenbank für SLDs
        ```
        mysql -uroot -proot -e 'create database sld charset utf8;'
        mysql -uroot -proot sld < /etc/whoisd/sld.mysql
        ```

     * whoisd
        ```
        export GOPATH=~/gocode
        go get github.com/openprovider/whoisd
        go get github.com/go-sql-driver/mysql

        systemctl enable whoisd.service
        systemctl start whoisd.service
        ```

     * Setup Apache Webserver als Proxy zum whoisd / Registrar Go-Interface
        ```
        a2dissite 000-default
        a2ensite sld-registrar
        a2enmod proxy proxy_http
        systemctl restart apache2
        ```

     * Einrichtung des Master Nameservers inkl. Key Files für Zonen
        ```
        KEY_DIR=/etc/bind/keys
        mkdir $KEY_DIR
        
        for tld in at com de net nl org pl se
        do
          dnssec-keygen -K $KEY_DIR -n ZONE -3 -f KSK -a RSASHA256 -b 2048 -r /dev/urandom -L 2400 -P now -A now ${tld}.
          dnssec-keygen -K $KEY_DIR -n ZONE -3 -a RSASHA256 -b 1024 -r /dev/urandom -L 2400 -P now -A now ${tld}.
        done
        ```

     * Records und SLD-Referenzen für TLD Zonen generieren und signieren
        ```
        /etc/bind/scripts/zone-update.sh
        ```

     * File mit DS-Records der TLDs auf Root-Nameserver kopieren
        ```
        scp /etc/bind/keys/dsset-* root@dnssec-rootns:/etc/bind/dssets/
        ```

   * dnssec-sldns

     * DNSSEC Keys für Test-Zonen anlegen
        ```
        KEY_DIR=/etc/bind/keys
        mkdir $KEY_DIR
        dnssec-keygen -K $KEY_DIR -n ZONE -3 -f KSK -a RSASHA256 -b 2048 -r /dev/urandom -L 600 -P now -A now dnsprovi.de
        dnssec-keygen -K $KEY_DIR -n ZONE -3 -f KSK -a RSASHA256 -b 2048 -r /dev/urandom -L 600 -P now -A now dnssec.de
        dnssec-keygen -K $KEY_DIR -n ZONE -3 -f KSK -a RSASHA256 -b 2048 -r /dev/urandom -L 600 -P now -A now task-walker.de
        dnssec-keygen -K $KEY_DIR -n ZONE -3 -f KSK -a RSASHA256 -b 2048 -r /dev/urandom -L 600 -P now -A now task-sigchase.de
        dnssec-keygen -K $KEY_DIR -n ZONE -3 -a RSASHA256 -b 1024 -r /dev/urandom -L 600 -P now -A now task-sigchase.de
        dnssec-keygen -K $KEY_DIR -n ZONE -3 -f KSK -a ECDSAP256SHA256 -r /dev/urandom -L 600 -P now -A now task-rollover.de
        dnssec-keygen -K $KEY_DIR -n ZONE -3 -f KSK -a ECDSAP256SHA256 -r /dev/urandom -L 600 -G task-rollover.de
        grep DNSKEY $KEY_DIR/*.key
        ```

     * DNSKEY Records der Zonen bei Registrar hinterlegen

     * Zonen signieren und regelmäßig per Cron ausführen
        ```
        /etc/bind/scripts/auto-signing.sh /etc/bind/zones
        ```

   * dnssec-resolver

     * DNSViz selbst einrichten
        ```
        cd /opt
        git clone https://github.com/dnsviz/dnsviz
        cd dnsviz
        git checkout v0.5.1
        python setup.py build
        python setup.py install
        ```

      * Auslieferung von DNSViz per Apache und mod_cgi
        ```
        a2enmod cgid
        # Konfiguration des DNSViz VHost in /etc/apache2/sites-available/dnsviz.test.conf
        a2dissite 000-default
        a2ensite dnsviz.test.conf
        mkdir /var/log/apache2/mod_cgi
        chown www-data: /var/log/apache2/mod_cgi
        systemctl reload apache2.service
        ```

      * Einrichtung GitWeb zum Download von Files durch Teilnehmer
        ```
        apt-get install gitweb
        mkdir /var/cache/git
        chown www-data: /var/cache/git
        cd /var/lib/git
        git clone https://github.com/pecharmin/dnssec-workshop.git
        a2ensite gitweb.test
        ```


1. Konfiguration der Slave Nameserver
    ```
    ln -s /etc/init.d/bind9 /etc/init.d/bind9.slave
    cp -aH /etc/default/bind9 /etc/default/bind9.slave
    # TODO: Init Setup
    sed -i -e 's@OPTIONS=.*@OPTIONS="-u bind -c /etc/bind9.slave/named.conf"@' /etc/default/bind9.slave
    cp -aH /var/lib/bind /var/lib/bind.slave
    cp -aH /var/cache/bind /var/cache/bind.slave
    ```


### Startup der DNS-Infrastruktur

Mit den folgenden Schritten wird der KVM-Wirt mit den virtuellen Systemen der Workshop-Infrastruktur konfiguriert und die VMs bereitgestellt. Die VMs wurden zuvor installiert.

1. Interface Konfiguration KVM Host mit Infrastruktur Systemen - `/etc/conf.d/net`
    ```
    config_br0="null"
    brctl_br0="setfd 0
    sethello 10
    stp off"
    bridge_br0="eth0"
    ```

. Netzwerk des KVM Hosts initialisieren
    ```
    bash scripts/kvm-init-net.sh
    ```

1. VMs der DNS Infrastruktur starten
    ```
    bash scripts/kvm-startup-vms.sh
    ```

1. Konfiguration des Docker Deamon -- `/etc/conf.d/docker`
    ```
    DOCKER_OPTS=" \
      --log-level=info \
      --iptables=false --ip-forward=true \
      -b=br0 --fixed-cidr=10.20.44.0/24 \
    "
    ```

    * Log Level setzen
    * Weiterleitung von IP-Pakten ohne Beschränkungen von iptables
    * Default Bridge für Netzwerk der Docker VMs
    * IP-Range für Docker Netzwerk


1. Startup der Docker Deamon für Teilnehmer VMs
    ```
    /etc/init.d/docker start
    ```

1. Docker Image vorbereiten
    ```
    cd ~/git/dnssec-workshop/docker/dnssec-bind
    mkdir -p shared dnssec-attendee ext
    sudo mount -o bind ../../shared shared
    sudo mount -o bind ../../dnssec-attendee dnssec-attendee
    sudo mount -o bind ../../ext ext

    docker build -t dnssec-bind .
    ```

1. Startup von Docker VMs für die Teilnehmer
    ```
    CID=ns50
    docker run --detach --net=bridge --dns=127.0.0.1 --hostname=$CID --name=$CID dnssec-bind
    echo -n "$CID: " ; docker inspect $(docker ps | grep $CID | cut -d' ' -f1) | grep '"IPAddress' | awk '{print $2}' | tr -d [\",] | uniq
    ```

1. Anzeigen aller Docker Container und deren IPs
    ```
    docker ps | grep -v CONTAINER | awk '{print $1,$NF}' | while read cid name ; do echo -n "$name: " ; docker inspect $cid | grep '"IPAddress' | awk '{print $2}' | tr -d [\",] | uniq ; done
    ```


/* vim: set syntax=markdown tabstop=2 expandtab: */
