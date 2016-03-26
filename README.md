# DNSSEC Workshop
In diesem Repository werden die Einrichtung, Informationen und Aufgaben für einen DNSSEC Workshop mit BIND 9 verwaltet.
Innerhalb des Workshops wird eine DNS-Infrastruktur bereitgestellt - angelehnt an das aktuelle Setup im Internet.
Die Teilnehmer des Workshops sollen sich mit einem eigenen Nameserver oder aus einem Docker Container in die Umgebung integrieren und anschließend DNSSEC für ihre DNS-Zonen einrichten.


## Umgebung
Die Workshop-Umgebung besteht aus folgenden Systemen:

* dnssec-rootns-a
  * Master Root-Nameserver a.root-servers.test.

* dnssec-rootns-b
  * Slave Root-Nameserver b.root-servers.test.

* dnssec-tldns-a
  * Master Nameserver für einen Teil der TLDs
  * whois Service
  * Domain Registrar Interface

* dnssec-tldns-b
  * Slave Nameserver für einen Teil der TLDs

* dnssec-sldns-a
  * Master Nameserver für SLDs mit DNSSEC-Beispielen

* dnssec-sldns-b
  * Slave Nameserver für SLDs

* dnssec-resolver
  * Nameserver als Resolver für Workshop-Umgebung
  * dnsviz Analyse-Tool + Non-Caching Nameserver
  * Git-Repository mit den Workshop-Informationen und Dateien
  * Webserver mit Files und Informationen inkl. Wiki

Als Netzwerk-Umgebung wird das Class B Net 10.20.0.0/16 verwenden.
Hier kann jeder Teilnehmer ein /24 Subnetz erhalten und ggf. mehrere IPs für seine Services konfigurieren.


## Rahmenbedingungen
* Jeder Teilnehmer bringt sein eigenes Notebook inkl. installiertem BIND Nameserver mit.
* Alternativ werden Docker Container mit den relevanten Services bereitgestellt.
* Teilnehmer verbinden sich per LAN zum oben beschriebenen fiktiven Internet.


## Referenzen
* https://talk.babiel.com/eh16/dnssec

* https://ftp.isc.org/isc/bind9/cur/9.9/doc/arm/Bv9ARM.html
* http://www.internetsociety.org/deploy360/dnssec/
* http://www.internetsociety.org/deploy360/resources/dane/
* http://dnsviz.net/demo/dnsviz-demo-v2.zip
* https://blog.cloudflare.com/tag/dnssec/

* https://tools.ietf.org/html/rfc3225

  Indicating Resolver Support of DNSSEC

* https://tools.ietf.org/html/rfc4035

  Protocol Modifications for the DNS Security Extensions

* https://tools.ietf.org/html/rfc4470

  Minimally Covering NSEC Records and DNSSEC On-line Signing

* https://tools.ietf.org/html/rfc5011

  Automated Updates of DNS Security (DNSSEC) Trust Anchors

* https://tools.ietf.org/html/rfc5155

  DNS Security (DNSSEC) Hashed Authenticated Denial of Existence

* https://tools.ietf.org/html/rfc6944

  Clarifications and Implementation Notes for DNS Security (DNSSEC)

* https://tools.ietf.org/html/rfc6840

  Applicability Statement: DNS Security (DNSSEC) DNSKEY Algorithm Implementation Status

* http://www.root-dnssec.org/wp-content/uploads/2010/06/icann-dps-00.txt

  DNSSEC Practice Statement for the Root Zone KSK Operator

* http://www.root-dnssec.org/wp-content/uploads/2010/06/vrsn-dps-00.txt

  DNSSEC Practice Statement for the Root Zone ZSK operator


## Tools
* http://dnsviz.net/
* http://dnssec-debugger.verisignlabs.com/
* https://www.dnssec-validator.cz/
* https://josefsson.org/walker/
* https://www.opendnssec.org/



/* vim: set syntax=markdown tabstop=2 expandtab: */
