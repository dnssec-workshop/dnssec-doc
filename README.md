# DNSSEC Workshop
In diesem Repository werden die Informationen, Guidelines, Konfigurationen und Scripte für einen DNSSEC Workshop mit BIND9 verwaltet.
Innerhalb des Workshops wird eine DNS-Infrastruktur bereitgestellt - angelehnt an das aktuelle Setup im Internet.
Die Teilnehmer des Workshops sollen sich mit einem eigenen Nameserver in die Umgebung integrieren und anschließend DNSSEC für ihre DNS-Zonen einrichten.

## Umgebung
Die Workshop-Umgebung besteht aus folgenden Systemen:
* dnssec-rootns
** Root-Nameserver root-servers.test.
** BIND Master- und Slave-Instanz
* dnssec-tldns
** Nameserver für einen Teil der TLDs
** BIND Master- und Slave-Instanz
** whois Service
** Domain Registrar Interface
* dnssec-resolver
** BIND Nameserver als Resolver für Workshop-Umgebung
** dnsviz Analyse-Tool
** Git-Repository mit den Workshop-Informationen und Dateien

## Rahmenbedingungen
* Jeder Teilnehmer bringt sein eigenes Notebook inkl. installiertem BIND Nameserver mit.
* Teilnehmer verbinden sich per LAN zum oben beschriebenen fiktiven Internet.
* Internet-Zugang ist über WLAN möglich.

## Referenzen
* (http://ftp.isc.org/isc/bind9/cur/9.9/doc/arm/Bv9ARM.html)
