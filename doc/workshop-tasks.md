# Tasks für den Workshop

* Jeder Teilnehmer kann mehrere BIND-Instanzen betreiben, um das DNSSEC Setup vollständig durchzuführen
  * 1x authoritativer Master Nameserver für SLDs
  * 1x authoritativer Slave Nameserver für SLDs
  * 1x Resolver für DNSSEC Validierung


## Umgebung konfigurieren
1. Konfiguriere Dein Netzwerk für den Workshop

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
        route add -net default gw 10.20.0.1
        
        echo "Your network configuration:"
        ip addr show dev ${NSIFACE}
        route -n
        ```

1. Konfiguriere Deinen Resolver für die Workshop Umgebung
    ```
    cp -aH /etc/resolv.conf /etc/resolv.conf.$(date +%Y%m%d_%H%M%S)
    echo 'nameserver 10.20.8.1' >/etc/resolv.conf
    ```

1. DNSKEY der Root-Nameserver einrichten
    ```
    cp -aH /etc/trusted-key.key /etc/trusted-key.key.$(date +%Y%m%d_%H%M%S)
    dig +noall +answer +multi -t DNSKEY . @10.20.1.1 | awk '/DNSKEY 257/,/; KSK;/ {print}' > /etc/trusted-key.key
    ```

## Umgebung erkunden
1. Einige Domains testen

1. Query DNS records of Zone task1.de
1. Trace DNS query from root servers down to task2.de
1. Get DNSSEC Records from de. domains (DNSKEY, NEC3, DS from Parent)
1. Get whois information about task3.de
1. List domains at SLD registrar


## Eigene Domain einrichten
* Register a new domain (name + nserver1_name)
* Edit your created domain (add a glue record)
* Configure a unsigned zone in your nameserver
** Check if your SLD is delivered by the TLD parent
** Test your SLD


## DNSSEC einrichten
* Create DNSKEYs for your zone and sign it
** Check your DNSSEC setup locally
* Publish your DNSSEC KSK to parent via SLD registrar
** Check the DNSSEC setup


## DNSSEC verwalten
* Add some new records to your zone and resign it - check the records
* Roll over your ZSK without parent interaction
** Check the DNSSEC setup
* Roll over your KSK with updating DNSKEYs in parent via SLD registrar
** Check the DNSSEC setup
* Roll over an alogrithm of your ZSK
** Check the DNSSEC setup
* Change from KSK/ZSK to CSK schema
** Check the DNSSEC setup


## Fehler provozieren und beheben
* Timings: TTL, Expire, Signatur


## Erweiterung des Setups
* Setup a slave nameserver for your SLD on local system
** Add the slave NS via SLD registrar to your domain
** Test the changed setup


/* vim: set syntax=markdown tabstop=2 expandtab: */
