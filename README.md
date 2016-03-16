# DNSSEC Workshop
In diesem Repository werden die Informationen, Guidelines, Konfigurationen und Scripte für einen DNSSEC Workshop mit BIND9 verwaltet.
Innerhalb des Workshops wird eine DNS-Infrastruktur bereitgestellt - angelehnt an das aktuelle Setup im Internet.
Die Teilnehmer des Workshops sollen sich mit einem eigenen Nameserver in die Umgebung integrieren und anschließend DNSSEC für ihre DNS-Zonen einrichten.

## Umgebung
Die Workshop-Umgebung besteht aus folgenden Systemen:
* dnssec-rootns
  * Root-Nameserver root-servers.test.
  * BIND Master- und Slave-Instanz
* dnssec-tldns
  * Nameserver für einen Teil der TLDs
  * BIND Master- und Slave-Instanz
  * whois Service
  * Domain Registrar Interface
* dnssec-sldns
  * Nameserver für das beispielhafte Setup von DNSSEC Zonen
  * BIND Master- und Slave-Instanz
* dnssec-resolver
  * BIND Nameserver als Resolver für Workshop-Umgebung
  * dnsviz Analyse-Tool
  * Git-Repository mit den Workshop-Informationen und Dateien
  * Webserver mit Files und Informationen

Als Netzwerk-Umgebung wird das Class B Net 10.20.0.0/16 verwenden.
Hier kann jeder Teilnehmer ein /24 Subnetz erhalten und ggf. mehrere IPs für seine Services konfigurieren.

## Rahmenbedingungen
* Jeder Teilnehmer bringt sein eigenes Notebook inkl. installiertem BIND Nameserver mit.
* Alternativ werden VMs mit den relevanten Services als Docker Container bereitgestellt.
* Teilnehmer verbinden sich per LAN zum oben beschriebenen fiktiven Internet.
* Internet-Zugang ist ggf. über WLAN des Dozenten möglich.

## Referenzen
* https://talk.babiel.com/dnssec-workshop
* https://ftp.isc.org/isc/bind9/cur/9.9/doc/arm/Bv9ARM.html
* http://www.internetsociety.org/deploy360/dnssec/
* http://www.internetsociety.org/deploy360/resources/dane/
* http://dnsviz.net/demo/dnsviz-demo-v2.zip

## Tools
* http://dnsviz.net/
* http://dnssec-debugger.verisignlabs.com/
* https://www.dnssec-validator.cz/
* https://josefsson.org/walker/
* https://www.opendnssec.org/



/* vim: set syntax=markdown tabstop=2 expandtab: */
