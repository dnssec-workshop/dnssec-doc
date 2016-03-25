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
        apt-get install make python-dnspython python-pygraphviz apache2
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
        dnssec-keygen -K $KEY_DIR -n ZONE -3 -a ECDSAP256SHA256 -r /dev/urandom -L 600 -P now -A none task-rollover.de
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

     * Elliptic Curve Verification Support einbauen
        ```
        apt-get install swig libssl-dev gcc python-dev

        cd /opt
        git clone https://gitlab.com/m2crypto/m2crypto.git
        cd m2crypto
        git chekout 0.23.0
        patch -p1 < /opt/dnsviz/contrib/m2crypto-0.23.patch
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

      * Einrichtung Dokumentation
        ```
        a2ensite doc.test
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


### Setup der DNS-Infrastruktur

1. Virtuelle Maschine mit Debian 8 installieren
    ```
    apt-get purge exim4 rpcbind portmap at avahi-daemon

    apt-get install dnsutils nmap tcpdump traceroute chkconfig curl git less screen bsd-mailx vim ntp ntpdate

    apt-get install apt-transport-https ca-certificates
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install docker-engine arping bridge-utils

    apt-get autoremove
    apt-get clean

    systemctl enable docker
    ```

    `/etc/systemd/logind.conf`
    ```
    HandleLidSwitch=ignore
    HandleLidSwitchDocked=ignore
    ```

    `/etc/ssh/sshd_config`
    ```
    UseDNS no
    PermitRootLogin yes
    ```


1. Interface Konfiguration KVM Host mit Infrastruktur Systemen

    `/etc/network/interfaces`
    ```
    source /etc/network/interfaces.d/*
    
    auto lo br0
    
    allow-hotplug th0
    iface eth0 inet manual
    
    iface br0 inet static
            bridge_ports eth0
            bridge_stp off     # disable Spanning Tree Protocol
            bridge_waitport 0  # no delay before a port becomes available
            bridge_fd 0
    
            address 10.20.0.X
            netmask 255.255.0.0
            network 10.20.0.0
            broadcast 10.20.255.255
            gateway 10.20.0.1
            dns-nameservers 8.8.8.8
    ```

1. Netzwerk des KVM Hosts initialisieren
    ```
    bash scripts/kvm-init-net.sh
    ```

1. VMs der DNS Infrastruktur starten
    ```
    bash scripts/kvm-startup-vms.sh
    ```

1. Konfiguration des Docker Deamon

    `/etc/default/docker`
    ```
    DOCKER_OPTS=" \
      --log-level=info \
      --iptables=false --ip-forward=true \
      -b=br0 --fixed-cidr=10.20.44.1/24 \
    "
    ```

    * Log Level setzen
    * Weiterleitung von IP-Pakten ohne Beschränkungen von iptables
    * Default Bridge für Netzwerk der Docker VMs
    * IP-Range für Docker Netzwerk

    `/etc/systemd/system/docker.service`
    ```
    [Service]
    EnvironmentFile=-/etc/default/docker
    ExecStart=/usr/bin/docker daemon -p /run/docker.pid $DOCKER_OPTS
    ```

1. Setup der Docker Umgebung
    ```
    cd /root 
    wget https://raw.githubusercontent.com/jpetazzo/pipework/master/pipework 
    chmod 755 pipework
    ```

    `/root/.bashrc`
    ```
    alias d=docker

    dls() {
        docker ps --format "{{.ID}}" | while read id; do docker inspect --format "{{.Id}} {{.Name}} {{.NetworkSettings.IPAddress}} {{.State.Status}}" $id; done
    }

    dps() {
        docker ps
    }

    drun() {
        CN=$1
        IP=$2
        TYPE=$3

        docker run --detach --net=bridge --dns=127.0.0.1 \
          --hostname=$CN --name=$CN dnssecworkshop/${TYPE:-dnssec-attendee} || ( echo $CN: docker run failed: $? ; return 1 )

        [ "$IP" ] && ( /root/pipework br0 $(docker inspect --format "{{.Id}}" $CN) $IP || ( echo $CN: pipework failed: $? ; return 2 ) )

        echo $CN: $(docker inspect --format "{{.NetworkSettings.IPAddress}}" $CN)
    }

    dstart() {
        CN=$1
        IP=$2

        docker start $CN || ( echo $CN: docker start failed: $? ; return 1 )

        [ "$IP" ] && ( /root/pipework br0 $(docker inspect --format "{{.Id}}" $CN) $IP || ( echo $CN: pipework failed: $? ; return 2 ) )

        echo $CN: $(docker inspect --format "{{.NetworkSettings.IPAddress}}" $CN)
    }
    ```

1. Startup der Docker Umgebung
    ```
    /etc/init.d/docker start
    ```

1. Docker VMs vorbereiten
    ```
    docker pull dnssecworkshop/dnssec-rootns-a
    docker pull dnssecworkshop/dnssec-rootns-b
    docker pull dnssecworkshop/dnssec-tldns-a
    docker pull dnssecworkshop/dnssec-tldns-b
    docker pull dnssecworkshop/dnssec-sldns-a
    docker pull dnssecworkshop/dnssec-sldns-b
    docker pull dnssecworkshop/dnssec-resolver
    docker pull dnssecworkshop/dnssec-attendee

    cat <<EOF > /root/dnssec-hosts
    dnssec-rootns-a 10.20.1.1/16
    dnssec-rootns-b 10.20.1.2/16
    dnssec-tldns-a 10.20.2.1/16
    dnssec-tldns-b 10.20.2.2/16
    dnssec-sldns-a 10.20.4.1/16
    dnssec-sldns-b 10.20.4.2/16
    dnssec-resolver 10.20.8.1/16
    EOF

    cat /root/dnssec-hosts | while read name ip
    do
        drun $name $ip $name
    done
    ```

1. Startup der Docker VMs für die Umgebung
    ```
    cat /root/dnssec-hosts | while read name ip
    do
        dstart $name $ip
    done
    ```

1. Startup von Docker VMs für die Teilnehmer
    ```
    dstart ns<id>
    ```

1. Anzeigen aller Docker Container und deren IPs
    ```
    dls
    ```



/* vim: set syntax=markdown tabstop=2 expandtab: */
