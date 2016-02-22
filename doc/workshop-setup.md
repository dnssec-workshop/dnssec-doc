# Workshop Setup

Alle im folgenden verwendeten Commands werden zur Vereinfachung unter dem User root ausgeführt.

## Informationen zur Workshop Umgebung
* dnssec-rootns
  * DNS Master:   10.20.1.1/16
  * DNS Slave:    10.20.1.2/16
* dnssec-tldns
  * DNS Master:   10.20.2.1/16
  * DNS Slave:    10.20.2.2/16
  * whois:        10.20.2.22/16
  * Webserver:    10.20.2.23/16
* dnssec-sldns
  * DNS Master:   10.20.4.1/16
  * DNS Slave:    10.20.4.2/16
* dnssec-resolver
  * DNS Resolver: 10.20.8.1/16
  * Webserver:    10.20.8.23/16

* Verfügbare TLDs:
  * it: keine Signierung mit DNSSEC
  * org: DS-Records nicht in Root-Servern eingetragen

## Vorbreitungen der Umgebung

### Setup virtueller Maschinen für die DNS-Infrastruktur

Es werden VMs mit verschiedenen Funktionen/Rollen für die Bereitstellung einer DNS-Infrastruktur als Workshop-Umgebung eingerichtet.

1. Grundinstallation
   * Debian 8 mit Basissystem

   * Software Setup
        ```
        apt-get purge exim4 rpcbind portmap at avahi-daemon
        apt-get install nmap tcpdump traceroute chkconfig curl git less screen bsd-mailx vim ntp ntpdate
        apt-get install bind9
        ```

2. Installation spezifischer Software auf den VMs
   * dnssec-tldns: whois + Domain Registrar Service
        ```
        apt-get install apache2 mysql-server golang-go libnet-dns-sec-perl
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

      * DNS-Zonen einmalig mit Keys signieren -- ist aufgrund fehlender Änderungen nicht erneut notwendig
         ```
	 /etc/bind/scripts/sign-zone.sh .
	 /etc/bind/scripts/sign-zone.sh test
         ```
      * DNSKEY der Root-Zone auf Resolvern einbinden
         ```
	 grep -h -R -A 10 "key-signing.*, for \.$" /etc/bind/keys/ | grep DNSKEY
         ```

   * dnssec-tldns
     * MySQL-Datenbank für SLDs
         ```
         mysql -uroot -proot -e 'create database sld charset utf8;'
         mysql -uroot -proot sld < /etc/whoisd/sld.mysql
         ```

     * whoisd
         ```
         # go get github.com/openprovider/whoisd
         go get github.com/pecharmin/whoisd
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

   * dnssec-resolver
     * DNSViz selbst einrichten
         ```
	 cd /opt
	 git clone https://github.com/pecharmin/dnsviz
	 cd dnsviz
	 git checkout v0.4.0
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

1. Interface Konfiguration KVM Host mit Infrastruktur Systemen - `/etc/conf.d/net`
	```
	config_br0="null"
	brctl_br0="setfd 0
	sethello 10
	stp off"
	bridge_br0="eth0"
	```

2. Netzwerk des KVM Hosts initialisieren
	```
	bash scripts/kvm-init-net.sh
	```

3. VMs der DNS Infrastruktur starten
	```
	bash scripts/kvm-startup-vms.sh
	```

4. In VMs: Default Route via KVM-Wirt setzen - optimalerweise in der Netzwerkkonfiguration persistieren
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

4. DNSKEY der Root-Nameserver einrichten
	```
	dig -t DNSKEY . @10.20.1.1
	echo ". 2400 IN DNSKEY 257 3 8 AwEAAcV2vdlE/+FeNmH4QNOqkeOx7T0v38prLujAggM4gmkBdj/v1DsE DaTEewoekBcXkhC8gQckDRwvMIZU1sSTGP5DYFAZEClpt0NCEJtlCIrS BHQnj2w9+J/iV3f0JC8oMLu727LiT/+Ro4DCSetithDd2Jqc4dsRnncC gsRzs2uC4h0GCXP/z25ZfweqL05t8rk5GAdTKpBiX/J2b1lqUaHC7UxK g0X/fv+SJ/8mYDSGFVssKlDEER4KwVxN6j2Ge44AOPMwE24hQ71faLYq vYwD+DPIClq/zom3REpFVw2PM77Yl3Hse7m6+CFHrsdMxN5IMm1qkxIq UNR43lKxDs0=" > /etc/trusted-key.key
	```

# vim: set syntax=markdown tabstop=4 expandtab:
