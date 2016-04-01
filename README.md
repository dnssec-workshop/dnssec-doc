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
Die Systeme der DNS-Infrastruktur laufen in dem Netzbereich 10.20.1.0 - 10.20.9.0.
Wenn Docker Container für die DNS-Infrastruktur oder Teilnehmer gestartet werden, erhalten diese Container eine IP-Adresse aus dem Management-Netz 10.20.44.0/24.
Den Teilnehmer-Container wird auf Basis des Container-Namens (`ns<id>`) eine IP-Adresse aus dem Netz 10.20.33.0/24 zugewiesen (ns3 -> 10.20.33.3).

Das Setup der Infrastruktur ist in https://github.com/dnssec-workshop/dnssec-doc/blob/master/workshop-setup.md beschrieben.


## Rahmenbedingungen
* Jeder Teilnehmer bringt sein eigenes Notebook inkl. installiertem BIND Nameserver mit.
* Alternativ werden Docker Container mit den relevanten Services bereitgestellt.
* Teilnehmer verbinden sich per LAN zum oben beschriebenen fiktiven Internet.


## Ablauf des Workshops

Vorstellung und Besprechung von DNSSEC:

* https://talk.babiel.com/eh16/dnssec

Tasks zu Hands-On DNSSEC:
* https://github.com/dnssec-workshop/dnssec-doc/blob/master/workshop-tasks.md


## Referenzen

* https://ftp.isc.org/isc/bind9/cur/9.9/doc/arm/Bv9ARM.html

* https://www.isc.org/blogs/dnssec-readiness/

* http://www.internetsociety.org/deploy360/dnssec/

* http://www.internetsociety.org/deploy360/resources/dane/

* https://blog.cloudflare.com/tag/dnssec/

* https://rick.eng.br/dnssecstat/

* http://dnssec.vs.uni-due.de/

* http://dnsviz.net/demo/dnsviz-demo-v2.zip

* https://www.dnssec-deployment.org/

* https://www.denic.de/wissen/dnssec/

* https://users.isc.org/~jreed/dnssec-guide/dnssec-guide.html

* https://www.dns-oarc.net/

* https://www.iana.org/assignments/dns-parameters

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

* https://tools.ietf.org/html/rfc6781

  DNSSEC Operational Practices, Version 2

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

* https://github.com/opendnssec/dnssec-monitor

* https://www.dnssec-tools.org/

* https://wiki.icinga.org/display/howtos/DNS+Monitoring

* https://github.com/opendnssec/dnssec-monitor



/* vim: set syntax=markdown tabstop=2 expandtab: */
