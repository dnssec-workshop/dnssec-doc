# Tasks für den Workshop

* Jeder Teilnehmer kann mehrere BIND-Instanzen betreiben, um das DNSSEC Setup vollständig durchzuführen
  * 1x authoritativer Master Nameserver für SLDs
  * 1x authoritativer Slave Nameserver für SLDs
  * 1x Resolver für DNSSEC Validierung


## Umgebung konfigurieren

Als erstes müssen die Geräte für den Workshop konfiguriert werden.
Du bekommst mehrere IPs in Deinem eigenen /24 Subnetz.

1. Konfiguriere Dein Netzwerk für den Workshop
    ```
    set -e
    [ $UID -ne 0 ] && echo "ERROR: You need to be root for this." && false
    
    read -p "Insert your attendee ID [32-255]>" NSID
    BASENET=10.20.0.0
    NETPREFIX=10.20.${NSID}
    NETSIZE=16
    NSIFACE=eth0
    NETGATEWAY=10.20.0.1
    
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
    route add -net default gw ${NETGATEWAY}
    
    echo "Your network configuration:"
    ip addr show dev ${NSIFACE}
    route -n
    ```

1. Konfiguriere Deinen Resolver für die Workshop Umgebung
    ```
    cp -aH /etc/resolv.conf /etc/resolv.conf.$(date +%Y%m%d_%H%M%S)
    echo 'nameserver 10.20.8.1' >/etc/resolv.conf
    ```


## Umgebung erkunden

Nachdem Du nun im Workshop-Netz bist, können wir einige Tests vornehmen und die Umgebung erkunden.

1. Einige Domains testen
    ```
    dig -t SOA dnsprovi.de
    dig dnssec.de
    ```

1. Nameserver der Root-Zone anzeigen
    ```
    dig -t NS .
    dig -t NS . @a.root-servers.test.
    dig -t SOA . @a.root-servers.test.
    dig -t SOA . @b.root-servers.test.
    ```

1. Welche Server liefern die TLD test. aus?
    ```
    dig -t NS test.
    ```

1. Rekursive Anfragen ab den Root-Servern herunter bis Domain task1.de ausführen
    ```
    dig +trace task-trace.de
    ```

1. Get whois information about task-whois.de
    ```
    whois -h whois.test task-whois.de
    ```


## DNSSEC Informationen 

Jetzt können wir uns die DNSSEC Informationen der Umgebung anzeigen lassen.

1. Lass Dir die DNSKEYs der Root-Server anzeigen.
    ```
    dig -t DNSKEY .
    ```

    * Unterschiede KSK (257) und ZSK (256)
    * Key Typ: 3 (DNSSEC)
    * Algorithmus: 8 (RSA SHA-256)
    * Details per dig anzeigen
        ```
        dig +noall +answer +multiline -t DNSKEY .
        ```
    * Key ID: Eindeutige Identifikation möglich


1. Richte den DNSKEY KSK der Root-Nameserver für das weitere Resolving ein.
    ```
    cp -aH /etc/trusted-key.key /etc/trusted-key.key.$(date +%Y%m%d_%H%M%S)
    dig +noall +answer +multi -t DNSKEY . @10.20.1.1 | awk '/DNSKEY 257/,/; KSK;/ {print}' > /etc/trusted-key.key
    ```

1. Zeige die DNSSEC Records der TLD de. an.
    ```
    dig +dnssec +multiline -t DNSKEY de.
    ```

    * Sind die Signaturen aktuell und vollständig?
    * Wo finden wir die DNSSEC Key IDs wieder?

1. Wie wird die TLD de. durch die Root-Zone authentifiziert?
    ```
    dig -t DS de.
    ```

    * Welchen DNSSEC Typ referenziert der DS-Records für de.?

1. Ist die Domain task-sigchase.de mit DNSSEC signiert?
    ```
    dig -t DNSKEY task-sigchase.de
    ```

1. Prüfe die Chain of Trust für die Domain task-sigchase.de.
    ```
    dig +sigchase +topdown task-sigchase.de
    ```

1. Die visualisierte der Prüfung kann auch per DNSViz erfolgen:
    http://dnsviz.test/graph.sh?domain=task-sigchase.de


## Eigene Domain einrichten

1. Lass Dir die aktuell registierten Domains anzeigen:
    * Webinterface http://whois.test/ aufrufen
    * Welche Nameserver und Handle sind für die Domain task-whois.de konfiguriert?

1. Lege Dir über das SLD-Interface zwei Domains an:
    * Domain 1 für die Verwaltung Deiner Nameserver-Umgebung.
    * Hier müssen Glue-Records eingetragen werden.
    * Die Nameserver der Domain 1 können als NS-Records für weitere Domains (ohne Glues) verwendet werden.
    * Lege Domain 2 mit den Nameservern aus Domain 1 an.

1. Prüfe die Registrierung per whois.

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
