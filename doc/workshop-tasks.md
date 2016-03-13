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

1. Erstelle Deine Zone Files:
    * Domain 1:
       * NS Glue Records
       * A-Records für Glue Nameserver zeigen auf eigene IP
       * A-Record auf beliebige IP
       * CNAME auf andere Zone
    * Domain 2:
       * NS-Records auf Domain 1
       * A-Record
       * CNAME

1. Lege Deine Konfiguration für BIND an:
    * Umgebung einrichten
    ```
    cp -aH /etc/bind /etc/bind.$(date +%Y%m%d_%H%M%S)
    cp -aH /var/cache/bind /var/cache/bind.$(date +%Y%m%d_%H%M%S)
    cp -aH /var/log/named /var/log/named.$(date +%Y%m%d_%H%M%S)

    rm -rI /etc/bind

    mkdir -p /etc/bind/zones /var/cache/bind /var/log/named
    chown bind: /var/cache/bind /var/log/named || chown named: /var/cache/bind /var/log/named
    ```

    * Config Files aus dnssec-attendee/ kopieren
       /etc/bind/named.conf
       /etc/bind/zones/hint.zone

    * Nameserver starten und prüfen
    ```
    named-checkconf /etc/bind/named.conf
    systemctl restart bind9.service || /etc/init.d/bind9 restart || /etc/init.d/named restart

    dig -t SOA domain1.tld. @localhost
    dig -t NS domain1.tld. @localhost
    dig -t SOA domain2.tld. @localhost
    dig -t NS domain2.tld. @localhost
    ```

1. Ist Deine Domain im TLD Nameserver eingetragen?
    ```
    dig +trace -t NS domain1.tld.
    dig +trace -t NS domain2.tld.
    ```


## DNSSEC Funktionen im Nameserver aktivieren

1. DNSSEC Validierung über lokalen Nameserver versuchen:
    ```
    dig +dnssec task-validation.de @localhost
    ```

1. DNSKEY der Root-Server als Trust Anchor einrichten:
    ```
    cat <<EOF > /etc/bind/managed.keys
    managed-keys {
      . initial-key 257 3 8 "AwEAAcV2vdlE/+FeNmH4QNOqkeOx7T0v38prLujAggM4gmkBdj/v1DsE DaTEewoekBcXkhC8gQckDRwvMIZU1sSTGP5DYFAZEClpt0NCEJtlCIrS BHQnj2w9+J/iV3f0JC8oMLu727LiT/+Ro4DCSetithDd2Jqc4dsRnncC gsRzs2uC4h0GCXP/z25ZfweqL05t8rk5GAdTKpBiX/J2b1lqUaHC7UxK g0X/fv+SJ/8mYDSGFVssKlDEER4KwVxN6j2Ge44AOPMwE24hQ71faLYq vYwD+DPIClq/zom3REpFVw2PM77Yl3Hse7m6+CFHrsdMxN5IMm1qkxIq UNR43lKxDs0=";
    };
    EOF
    ```

1. DNSSEC im Nameserver aktivieren:
    /etc/bind/named.conf
    ```
    include "/etc/bind/managed.keys";

    dnssec-enable yes;
    dnssec-validation yes;
    ```

    ```
    named-checkconf /etc/bind/named.conf
    systemctl restart bind9.service || /etc/init.d/bind9 restart || /etc/init.d/named restart
    ```

1. DNSSEC Validierung prüfen:
    ```
    dig +dnssec task-validation.de @localhost
    ```

## DNSSEC für Domain einrichten

1. DNSSEC Keys für Zonen anlegen
    ```
    KEY_DIR=/etc/bind/keys
    mkdir $KEY_DIR

    dnssec-keygen -K $KEY_DIR -n ZONE -3 -f KSK -a RSASHA256 -b 2048 -r /dev/urandom -L 300 -P now -A now domain1.tld
    dnssec-keygen -K $KEY_DIR -n ZONE -3        -a RSASHA256 -b 1024 -r /dev/urandom -L 300 -P now -A now domain1.tld
    ```

1. DNSKEY Files untersuchen
    * Dateiname
    * private File
    * key File

1. Zonen mit DNSKEYs signieren
    ```
    # Serial der Zone domain1.tld inkrementieren

    dnssec-signzone -S -K $KEY_DIR -d $KEY_DIR -e +2h -j 300 -r /dev/urandom -a -3 $(openssl rand 4 -hex) -H 15 -A -o domain1.tld. /etc/bind/zones/domain1.tld.zone

    rndc reload
    ```

1. Zustand der Zonen prüfen
    ```
    dig -t DNSKEY domain1.tld. @localhost
    ```

1. Nameserver Konfiguration für Zone File auf signierte Version anpassen
    ```
    file "/etc/bind/zones/domain1.tld.signed";
    rndc reload
    ```

1. Zustand der Zonen prüfen
    ```
    dig -t DNSKEY domain1.tld. @localhost
    ```

    http://dnsviz.test/

1. Publikation des KSK im Parent via SLD Registrar Webinterface
    * KSK anzeigen
    ```
    cat /etc/bind/keys/Kdomain1.tld.*.key
    ```

    * Whois Update der Domain -- http://whois.test/
      * DNSSEC Key 1 flags: 257
      * DNSSEC Key 1 algorithm_id: 8
      * DNSSEC Key 1 key_data: anzeigte Daten aus Keyfile

1. Chain of Trust prüfen
    * http://dnsviz.test/
    * per Command Line Tool
    ```
    dig +sigchase +topdown domain1.tld.
    ```

## DNSSEC verwalten

1. Füge einige DNS Records in Deiner Zone ein und signiere sie erneut
    ```
    vi /etc/bind/zones/domain1.tld
    dnssec-signzone [...]
    ```

    * Serial erhöhen nicht vergessen ;-P

1. Führe einen ZSK Rollover (per Pre-Publish) ohne Interaktion mit der Parent TLD aus
    ```
    KEY_DIR=/etc/bind/keys

    # Neuen ZSK generieren und in Zone publizieren
    dnssec-keygen -K $KEY_DIR -n ZONE -3 -a RSASHA256 -b 1024 -r /dev/urandom -L 300 -P now -A +1h domain1.tld
    # Serial der Zone inkrementieren und Zone neu signieren
    dnssec-signzone [...]
    rndc reload

    # Warten bis Key öffentlich verfügbar ist (DNSKEY TTL auslaufen lassen)

    # TESTEN

    # Neuen ZSK für das Signieren aktivieren
    dnssec-settime -A now $KEY_DIR/K<name>+<alg>+<id>.key

    # Alten ZSK nach DNSKEY TTL nicht mehr zum Signieren nehmen
    dnssec-settime -I +330 $KEY_DIR/K<name>+<alg>+<id>.key

    # Serial inkrementieren und Zone neu signieren
    dnssec-signzone [...]
    rndc reload

    # TESTEN

    # Keys und Signaturen prüfen
    # Maximum Zone TTL abwarten

    # TESTEN

    # Alten ZSK raus nehmen
    dnssec-settime -D now $KEY_DIR/K<name>+<alg>+<id>.key

    # Serial inkrementieren und Zone neu signieren
    dnssec-signzone [...]
    rndc reload

    # TESTEN
    ```

1. Führe einen KSK Rollover (per Double Signature) inkl. Interaktion mit dem Parent aus
    ```
    KEY_DIR=/etc/bind/keys

    # Neuen KSK generieren und in Zone publizieren
    # Neuer Key soll ZSKs direkt signieren
    dnssec-keygen -K $KEY_DIR -n ZONE -f KSK -3 -a RSASHA256 -b 1024 -r /dev/urandom -L 300 -P now -A now domain1.tld
    # Serial der Zone inkrementieren und Zone neu signieren
    dnssec-signzone [...]
    rndc reload

    # TESTEN

    # Warten bis Key öffentlich verfügbar ist (DNSKEY TTL auslaufen lassen)

    # Neuen DNSKEY der Domain in der TLD eintragen lassen - http://whois.test/

    # TESTEN

    # Größere TTL abwarten: DS des Parent ODER Maximum Zone TTL eigener Domain

    # TESTEN

    # Alten KSK rausnehmen und Zone
    dnssec-settime -D now $KEY_DIR/K<name>+<alg>+<id>.key

    # Serial inkrementieren und Zone neu signieren
    dnssec-signzone [...]
    rndc reload

    # TESTEN
    ```

1. Rollover zu einem CSK Schema
    ```
    KEY_DIR=/etc/bind/keys

    # Serial der Zone inkrementieren
    # KSK zum Signieren allen Records verwenden
    dnssec-signzone -z [...]
    rndc reload

    # TESTEN

    # Maximum Zone TTL abwarten

    # TESTEN

    # Überflüssigen ZSK raus nehmen
    dnssec-settime -D now $KEY_DIR/K<name>+<alg>+<id>.key

    # Serial inkrementieren und Zone neu signieren
    dnssec-signzone [...]
    rndc reload

    # TESTEN 
    ```

## Automatisierung des Zone Signings

1. Basis-Konfiguration im BIND vornehmen
    ```
    server {
        edns yes; # default
        edns-udp-size 4096; # default
    };

    options {
        dnssec-enable yes;
        key-directory "/etc/bind/dnssec";
        random-device "/dev/urandom";
        dnssec-update-mode maintain; # default
        dnssec-loadkeys-interval 10; # 10 minutes
        sig-validity-interval 7 4; # 7 day lifetime
                                   # resigning 4 days before expiration
                                   # -> signature lifetime window: 3 days
    };
    ```

1. Zonen-Konfiguration anpassen
    ```
    zone "domain2.tld." IN {
        type master;
        file "/etc/bind/zones/domain2.tld.zone";
        auto-dnssec maintain;
        inline-signing yes;
        #update-check-ksk no; # bei Bedarf 'no' für CSK Schema
                              # no == KSK auch als ZSK nutzen
        #update-policy local; # für nsupdate von localhost
    };
    ```

1. Zone mit DNSSEC signieren und NSEC3 einrichten
    ```
    rndc reload

    # TESTEN

    rndc sign domain2.tld
    rndc signing -nsec3param 1 0 20 $(openssl rand 4 -hex) domain2.tld

    # TESTEN
    ```

1. Zonendaten aktualisieren

    * Traditionell
    ```
    rndc freeze domain2.tld
    vi /etc/bind/zones/domain2.tld
    rndc thaw domain2.tld
    ```

    * nsupdate
    ```
    nsupdate -l
    zone domain2.tld
    ttl 900
    update add foobar.domain2.tld. CNAME whois.test.
    show
    send
    answer
    quit
    ```


## Weitere DNSSEC Informationen prüfen

1. Signing Schemata vergleichen
    * task-sigchase.de -- KSK & ZSK
    * dnsprovi.de -- CSK
    * task-rollover.de -- Backup KSK

1. Zone Expire VS. Signatur-Zeitraum

1. Zone Expire & NSEC Signatur-Zeitraum

1. NSEC(3) Zone Walking
    * https://josefsson.org/walker/
    * /etc/bind/scripts/nsec-walker/
    * `walker -x task-walker.de`


## Fehler provozieren und beheben

1. TCP-Anfragen unterbinden
1. Signaturen auslaufen lassen
1. Falschen DS im Parent publizieren
1. KSK oder ZSK löschen/deaktivieren
1. TTL=0 für Records verwenden
1. TTLs auf geringen Wert setzen


## Erweiterung des Setups

1. BIND Inline Signing

1. Bump on Wire Signing mit anderen Teilnehmern einrichten

1. Slave Nameserver für Zonen einrichten (TSIG)



/* vim: set syntax=markdown tabstop=2 expandtab: */
