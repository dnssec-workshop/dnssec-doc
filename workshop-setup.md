# Workshop Setup

Für Informationen zur Workshop-Umgebung siehe https://github.com/dnssec-workshop/dnssec-doc/README.md

Die für die Workshop Umgebung benötigten Systeme laufen als Docker Container in einer virtuellen Maschine.
Nachfolgend wird die Einrichtung der VM und der Docker Container beschrieben.

Alle im folgenden verwendeten Commands werden zur Vereinfachung unter dem User root ausgeführt.

## Vorbreitungen der Umgebung

### Setup der Workshop Infrastruktur

1. Virtuelle Maschine mit Debian 8 als Docker Host installieren
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

1. Interface Konfiguration für Docker Infrastruktur

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
    
            address 10.20.0.2
            netmask 255.255.0.0
            network 10.20.0.0
            broadcast 10.20.255.255
            #gateway 10.20.0.1
            dns-nameservers 8.8.8.8
    ```

    `/etc/hosts`
    ```
    # DNSSEC Workshop
    10.20.1.1 dnssec-rootns-a
    10.20.1.2 dnssec-rootns-a
    10.20.2.1 dnssec-tldns-a
    10.20.2.2 dnssec-tldns-b
    10.20.4.1 dnssec-sldns-a
    10.20.4.2 dnssec-sldns-b
    10.20.8.1 dnssec-resolver
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
        docker ps -a --format "{{.ID}}" | while read id; do docker inspect --format "{{.Id}} {{.Name}} {{.NetworkSettings.IPAddress}} {{.State.Status}}" $id; done | tr -d /
    }

    dps() {
        docker ps
    }

    drun() {
        CN=$1
        IP=${2:-"10.20.33.${CN/ns}/16"}
        TYPE=$3

        docker run --detach --net=bridge --dns=127.0.0.1 \
          --hostname=$CN --name=$CN dnssecworkshop/${TYPE:-"dnssec-attendee"} || ( echo $CN: docker run failed: $? ; return 1 )

        [ "$IP" ] && ( /root/pipework br0 $(docker inspect --format "{{.Id}}" $CN) $IP || ( echo $CN: pipework failed: $? ; return 2 ) )

        echo $CN: $(docker inspect --format "{{.NetworkSettings.IPAddress}}" $CN) - $IP
    }

    dstart() {
        CN=$1
        IP=${2:-"10.20.33.${CN/ns}/16"}

        docker start $CN || ( echo $CN: docker start failed: $? ; return 1 )

        [ "$IP" ] && ( /root/pipework br0 $(docker inspect --format "{{.Id}}" $CN) $IP || ( echo $CN: pipework failed: $? ; return 2 ) )

        echo $CN: $(docker inspect --format "{{.NetworkSettings.IPAddress}}" $CN) - $IP
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
