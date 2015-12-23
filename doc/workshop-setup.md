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

### Setup der DNS-Infrastruktur

1. Interface Konfiguration KVM Host mit Infrastruktur Systemen
`/etc/conf.d/net`
	config_br0="null"
	brctl_br0="setfd 0
	sethello 10
	stp off"
	bridge_br0="eth0"

2. Netzwerk Setup
	/etc/init.d/net.br0 start
	ip addr flush dev br0
	ip addr add local 10.20.0.1/16 dev br0 scope link
	route add -net 10.20.0.0/16 dev br0

3. Startup der Systeme für die DNS Infrastruktur
	/etc/init.d/libvirtd start
	virsh start dnssec-rootns
	virsh start dnssec-tldns
	virsh start dnssec-sldns
	virsh start dnssec-resolver


### Konfiguration der Nameserver-Instanzen
	ln -s /etc/init.d/bind9 /etc/init.d/bind9.slave
	cp -aH /etc/default/bind9 /etc/default/bind9.slave
	# TODO: Init Setup
	sed -i -e 's@OPTIONS=.*@OPTIONS="-u bind -c /etc/bind9.slave/named.conf"@' /etc/default/bind9.slave
	cp -aH /var/lib/bind /var/lib/bind.slave
	cp -aH /var/cache/bind /var/cache/bind.slave

## Konfiguration von Systemen der Teilnehmer

* Jeder Teilnehmer kann mehrere BIND-Instanzen betreiben, um das DNSSEC Setup vollständig durchzuführen
  * 1x authoritativer Master Nameserver für SLDs
  * 1x authoritativer Slave Nameserver für SLDs
  * 1x Resolver für DNSSEC Validierung

1. IP-Forwarding deaktivieren
	echo 0 > /proc/sys/net/ipv4/ip_forward
# Netzwerk konfigurieren: Teilnehmer erhalten mehrere IPs in einem Subnetz
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
	
	echo "Setting up your named configurations..."
	NAMED_INSTANCES="master slave resolver"
	
	mkdir -p ${NAMED_BASEDIR}
	
	for nsinstance in ${NAMED_INSTANCES}
	do
		mkdir -p ${NAMED_BASEDIR}/etc/named.${nsinstance}
		mkdir -p ${NAMED_BASEDIR}/var/log/named.${nsinstance}
		chown bind: ${NAMED_BASEDIR}/var/log/named.${nsinstance} || chown named: ${NAMED_BASEDIR}/var/log/named.${nsinstance}
	done
