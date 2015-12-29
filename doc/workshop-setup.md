# Workshop Setup

## Informationen zur Workshop Umgebung
* dnssec-rootns
  * DNS Master:   10.20.1.1/16
  * DNS Slave:    10.20.1.2/16
* dnssec-tldns
  * DNS Master:   10.20.2.1/16
  * DNS Slave:    10.20.2.2/16
  * Webserver:    10.20.2.8/16
* dnssec-sldns
  * DNS Master:   10.20.4.1/16
  * DNS Slave:    10.20.4.2/16
* dnssec-resolver
  * DNS Resolver: 10.20.8.1/16
  * Webserver:    10.20.8.8/16

## Vorbreitungen der Umgebung

### Setup virtueller Maschinen für die DNS-Infrastruktur

Es werden VMs mit verschiedenen Funktionen/Rollen für die Bereitstellung einer DNS-Infrastruktur als Workshop-Umgebung eingerichtet.

1. Grundinstallation
   * Debian 8 mit Basissystem
   * Software Setup
	```
	apt-get purge exim4 rpcbind portmap at avahi-daemon
	apt-get install nmap tcpdump traceroute chkconfig curl git less screen bsd-mailx vim
	apt-get install bind9
	```

2. Installation spezifischer Software auf den VMs
   * dnssec-tldns
	```
	apt-get install apache2 mysql-server golang-go
	```
   * dnssec-resolver
	```
	apt-get install apache2
	```


### Software-Konfiguration der Nameserver VMs

#### Konfiguration der Nameserver-Instanzen
1. Konfiguration der Master Nameserver
   siehe (dnssec-<instance>/)

1. Git-Repository laden
         ```
         cd /root
         git clone https://github.com/pecharmin/dnssec-workshop.git
         rsync -av dnssec-workshop/$HOSTNAME/ /
         ```

1. Einrichtung der Software-Komponenten auf den Nameserver VMs
   * dnssec-tldns
     * MySQL-Datenbank für SLDs
         ```
         mysql -uroot -proot -e 'create database sld charset utf8;'
         mysql -uroot -proot sld < /etc/whoisd/sld.mysql
         ```
     * whoisd
         ```
cat <<EOF >>/root/.bashrc

# DNSSEC Testing
export GOPATH=/root/gocode
export PATH=$PATH:$GO_PATH/bin
EOF

         # go get github.com/openprovider/whoisd
         go get github.com/pecharmin/whoisd
         go get github.com/go-sql-driver/mysql

         systemctl enable whoisd.service
         systemctl start whoisd.service
         ```

2. Konfiguration der Slave Nameserver
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

1. Interface Konfiguration KVM Host mit Infrastruktur Systemen -- `/etc/conf.d/net`
	```
	config_br0="null"
	brctl_br0="setfd 0
	sethello 10
	stp off"
	bridge_br0="eth0"
	```

2. Netzwerk Setup
	```
	/etc/init.d/net.br0 start
	ip addr flush dev br0
	ip addr add local 10.20.0.1/16 dev br0 scope link
	route add -net 10.20.0.0/16 dev br0
	```

3. Startup der Systeme für die DNS Infrastruktur
	```
	/etc/init.d/libvirtd start
	virsh start dnssec-rootns
	virsh start dnssec-tldns
	virsh start dnssec-sldns
	virsh start dnssec-resolver
	```

4. Traffic der virtuellen Systeme über Interface mit Internet-Anbindungen maskieren
	```
	echo 1 > /proc/sys/net/ipv4/ip_forward
	INET_INTERFACE=wlan0
	iptables -t nat -A POSTROUTING -s 10.20.0.0/16 -o $INET_INTERFACE -j MASQUERADE
	```

5. In VMs: Default Route via KVM-Wirt setzen
	```
	# route add -net default gw 10.20.0.1
	```


## Konfiguration von Systemen der Teilnehmer

* Jeder Teilnehmer kann mehrere BIND-Instanzen betreiben, um das DNSSEC Setup vollständig durchzuführen
  * 1x authoritativer Master Nameserver für SLDs
  * 1x authoritativer Slave Nameserver für SLDs
  * 1x Resolver für DNSSEC Validierung

1. IP-Forwarding deaktivieren
	```
	echo 0 > /proc/sys/net/ipv4/ip_forward
	```

2. Netzwerk konfigurieren: Teilnehmer erhalten mehrere IPs in einem Subnetz
	```
	set -e
	[ $UID -ne 0 ] && echo "ERROR: You need to be root for this." && false

	NSID=42
	BASENET=10.20.0.0
	NETPREFIX=10.20.${NSID}
	NETSIZE=16
	NSIFACE=eth0
	
	NAMED_BASEDIR=/root/dnssec-workshop
	
	link_status=`ip link show dev ${NSIFACE}`
	echo "Your link state: $link_status"
	echo "$link_status" | grep "state UP"
	
	ip addr flush dev ${NSIFACE}
	ip addr add local ${NETPREFIX}.3/${NETSIZE} dev ${NSIFACE} scope link label ${NSIFACE}.client
	ip addr add local ${NETPREFIX}.13/${NETSIZE} dev ${NSIFACE} scope link label ${NSIFACE}.master
	ip addr add local ${NETPREFIX}.19/${NETSIZE} dev ${NSIFACE} scope link label ${NSIFACE}.slave
	ip addr add local ${NETPREFIX}.18/${NETSIZE} dev ${NSIFACE} scope link label ${NSIFACE}.resolver
	route add -net ${BASENET}/${NETSIZE} dev ${NSIFACE}
	
	echo "Your network configuration:"
	ip addr show dev ${NSIFACE}
	route -n
	```
	
3. Verzeichnisse und Dateien für BIND-Nameserver einrichten
	```
	echo "Setting up your named configurations..."
	NAMED_INSTANCES="master slave resolver"
	
	mkdir -p ${NAMED_BASEDIR}
	
	for nsinstance in ${NAMED_INSTANCES}
	do
		mkdir -p ${NAMED_BASEDIR}/etc/named.${nsinstance}
		mkdir -p ${NAMED_BASEDIR}/var/log/named.${nsinstance}
		chown bind: ${NAMED_BASEDIR}/var/log/named.${nsinstance} || chown named: ${NAMED_BASEDIR}/var/log/named.${nsinstance}
	done
	```
