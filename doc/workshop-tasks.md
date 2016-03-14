## Informationen und Setup der Workshop Umgebung

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
  * at, com, de, it, net, nl, org, pl, se, test
  * test: Domain für interne Workshop-Services
  * it: keine Signierung mit DNSSEC
  * org: DS-Records nicht in Root-Servern eingetragen

* Mitmachen:
  * Docker VM
  * Eigenes Gerät

* Netzwerkumgebung
  * Netz: 10.20.0.0/16
  * Gateway: 10.20.0.1
  * Du bekommst Dein eigenes /24 Subnetz.
  * Subnetz von 50 bis 255 -- 10.20.${NETID}.1/16
    ```
    ifconfig eth0 10.20.X.1/16
    ```

  * Konfiguriere Deinen Resolver für die Workshop Umgebung
    * Nicht in Docker VMs notwendig
    ```
    echo 'nameserver 10.20.8.1' >/etc/resolv.conf
    ```

  * Auf Deinem Rechner brauchst Du ggf. Host-Einträge, wenn die Resolver-Konfiguration nicht angepasst ist
    ```
    10.20.2.1 whois.test nic.test
    10.20.8.1 dnsviz.test resolver.test gitweb.test
    ```

* Verfügbare Services:
  * Default Router / ggf. Gateway ins Internet
    ```
    route add -net default gw 10.20.0.1
    ```

  * Registrierung von Domains
  * Whois Service über Domains
  * DNS-Resolver mit DNSSEC-Support: `resolver.test` / `10.20.8.1`
    ```
    dig -t ANY test. @10.20.8.1
    ```
  * GitWeb mit relevanten Daten zum Workshop \\
    http://gitweb.test/

  * Workshop Anleitungen \\
    http://wiki.test/

  * DNSViz Debugging


## Umgebung erkunden

Nachdem Du nun im Workshop-Netz bist, können wir einige Tests vornehmen und die Umgebung erkunden.

1. Einige Domains testen
    ```
    dig -t SOA dnsprovi.de
    ```

1. Nameserver der Root-Zone anzeigen
    ```
    dig -t NS .
    ```

1. Welche Server liefern die TLD `test.` aus?
    ```
    dig -t NS test.
    ```

1. Rekursive Anfragen ab den Root-Servern herunter bis Domain `task1.de.` ausführen
    ```
    dig +trace +nodnssec task-trace.de.
    ```

1. Whois Informationen der Doamin `task-whois.de.` abfragen
    ```
    whois -h whois.test task-whois.de
    ```


## DNSSEC Informationen 

Jetzt können wir die Umgebung nach DNSSEC Informationen erkunden.

1. Zeige die DNSSEC Records der TLD de. an.
    ```
    dig +dnssec +multiline -t DNSKEY de.
    ```

    * Unterschiede KSK (257) und ZSK (256)
    * Key Typ: 3 (DNSSEC)
    * Algorithmus: 8 (RSA SHA-256)
    * Key ID: Eindeutige Identifikation möglich
    * Wo finden wir die DNSSEC Key IDs wieder?
    * Sind die Signaturen aktuell und vollständig?

1. Wie wird die TLD de. durch die Root-Zone authentifiziert?
    ```
    dig -t DS de.
    ```

    * Welchen DNSSEC Typ referenziert der DS-Records für de.?

1. Ist die Domain `task-sigchase.de.` mit DNSSEC signiert?
    ```
    dig -t DNSKEY task-sigchase.de.
    ```

1. Richte den DNSKEY KSK der Root-Nameserver für die Authentifizierung der Records ein:
    * Nicht in Docker VMs notwendig
    ```
    cp -aH /etc/trusted-key.key \
           /etc/trusted-key.key.$(date +%Y%m%d_%H%M%S)

    dig +noall +answer +multi -t DNSKEY . @10.20.1.1 | \
      awk '/DNSKEY 257/,/; KSK;/ {print}' > /etc/trusted-key.key
    ```

1. Prüfe die Chain of Trust für die Domain `task-sigchase.de.`
    ```
    dig +sigchase +topdown task-sigchase.de.
    ```

1. Die visualisierte der Prüfung kann auch per DNSViz erfolgen:
    * http://dnsviz.test/graph.sh?domain=task-sigchase.de


## Eigene Domain einrichten

1. Lass Dir die aktuell registierten Domains anzeigen:
    * Webinterface http://whois.test/ aufrufen
    * Welche Nameserver und Handles sind für die Domain `task-whois.de` konfiguriert?

1. Lege Dir über das SLD-Interface zwei Domains an:
    * `domain1.tld`
        * Verwaltung Deiner Nameserver-Umgebung.
        * Hier müssen Glue-Records eingetragen werden!
            * `ns1.domain1.tld` -- `10.20.44.X`
            * `ns2.domain1.tld` -- `10.20.44.X`
        * Die Nameserver von `domain1.tld` können als NS-Records für weitere Domains (ohne Glues) verwendet werden.
    * `domain2.tld`
        * Lege `domain2.tld` mit den Nameservern von `domain1.tld` an:
            * `ns1.domain1.tld`
            * `ns2.domain1.tld`

1. Prüfe die Registrierung per whois.
    ```
    whois -h whois.test domain1.tld
    whois -h whois.test domain2.tld
    ```

1. Lege Deine Konfiguration für BIND an:
    * Umgebung einrichten -- nicht in Docker VMs notwendig
    ```
    cp -aH /etc/bind /etc/bind.$(date +%Y%m%d_%H%M%S)
    cp -aH /var/cache/bind /var/cache/bind.$(date +%Y%m%d_%H%M%S)
    cp -aH /var/log/named /var/log/named.$(date +%Y%m%d_%H%M%S)

    rm -rI /etc/bind

    mkdir -p /etc/bind/zones /var/cache/bind /var/log/named
    chown bind: /var/cache/bind /var/log/named || \
    chown named: /var/cache/bind /var/log/named
    ```

    * Config Files aus `dnssec-attendee/` kopieren -- nicht in Docker VMs notwendig
       * `/etc/bind/named.conf`
       ```
       curl 'http://gitweb.test/gitweb.cgi?p=dnssec-workshop/.git;a=blob_plain;f=dnssec-attendee/etc/bind/named.conf' >/etc/bind/named.conf
       ```

       * `/etc/bind/zones/hint.zone`
       ```
       curl 'http://gitweb.test/gitweb.cgi?p=dnssec-workshop/.git;a=blob_plain;f=shared/etc/bind/zones/hint.zone' >/etc/bind/zones/hint.zone
       ```

1. Erstelle Deine Zone Files:
    * `domain1.tld`:
       * NS Glue Records
       * A-Records für Glue Nameserver zeigen auf eigene IP
       * A-Record auf beliebige IP
       * CNAME auf andere Zone
    * `domain2.tld`:
       * NS-Records von `domain1.tld`
       * A-Record
       * CNAME

1. Nameserver starten und prüfen
    ```
    named-checkconf /etc/bind/named.conf
    systemctl restart bind9.service || \
    /etc/init.d/bind9 restart || \
    /etc/init.d/named restart
    ```

1. Setup prüfen
    ```
    dig -t SOA domain1.tld. @localhost
    dig -t NS domain1.tld. @localhost
    ```

1. Ist Deine Domain im TLD Nameserver eingetragen?
    ```
    dig +trace -t NS domain1.tld.
    ```


## DNSSEC Funktionen im Nameserver aktivieren

1. DNSSEC Validierung über lokalen Nameserver versuchen:
    ```
    dig +dnssec task-validation.de @localhost
    ```

1. DNSKEY der Root-Server als Trust Anchor einrichten:
    * Nicht in Docker VM notwendig
       * Option A
       ```
       cat <<EOF > /etc/bind/managed.keys
       managed-keys {
         . initial-key 257 3 8 "AwEAAcV2vdlE/+FeNmH4QNOqkeOx7T0v38prLujAggM4gmkBdj/v1DsE DaTEewoekBcXkhC8gQckDRwvMIZU1sSTGP5DYFAZEClpt0NCEJtlCIrS BHQnj2w9+J/iV3f0JC8oMLu727LiT/+Ro4DCSetithDd2Jqc4dsRnncC gsRzs2uC4h0GCXP/z25ZfweqL05t8rk5GAdTKpBiX/J2b1lqUaHC7UxK g0X/fv+SJ/8mYDSGFVssKlDEER4KwVxN6j2Ge44AOPMwE24hQ71faLYq vYwD+DPIClq/zom3REpFVw2PM77Yl3Hse7m6+CFHrsdMxN5IMm1qkxIq UNR43lKxDs0=";
       };
       EOF
       ```

       * Option B
       ```
       curl 'http://gitweb.test/gitweb.cgi?p=dnssec-workshop/.git;a=blob_plain;f=shared/etc/bind/managed.keys' >/etc/bind/managed.keys
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
    systemctl restart bind9.service || \
    /etc/init.d/bind9 restart || \
    /etc/init.d/named restart
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

    dnssec-keygen -K $KEY_DIR -n ZONE -3 -f KSK \
    -a RSASHA256 -b 2048 -r /dev/urandom -L 300 \
    -P now -A now domain1.tld

    dnssec-keygen -K $KEY_DIR -n ZONE -3 \
    -a RSASHA256 -b 1024 -r /dev/urandom -L 300 \
    -P now -A now domain1.tld
    ```

1. DNSKEY Files untersuchen
    * Dateiname
    * private File
    * key File

1. Zonen mit DNSKEYs signieren
    ```
    # Serial der Zone domain1.tld inkrementieren

    dnssec-signzone -S -K $KEY_DIR -d $KEY_DIR \
    -e +2h -j 300 -r /dev/urandom -a \
    -3 $(openssl rand 4 -hex) -H 15 -A \
    -o domain1.tld. /etc/bind/zones/domain1.tld.zone

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
    dnssec-keygen -K $KEY_DIR -n ZONE -3 -a RSASHA256 -b 1024 \
    -r /dev/urandom -L 300 -P now -A +1h domain1.tld

    # Serial der Zone inkrementieren und Zone neu signieren
    dnssec-signzone [...]
    rndc reload

    # Warten bis Key öffentlich verfügbar ist 
    #  (DNSKEY TTL auslaufen lassen)

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
    dnssec-keygen -K $KEY_DIR -n ZONE -f KSK -3 -a RSASHA256 -b 2048 \
    -r /dev/urandom -L 300 -P now -A now domain1.tld

    # Serial der Zone inkrementieren und Zone neu signieren
    dnssec-signzone [...]
    rndc reload

    # TESTEN

    # Warten bis Key öffentlich verfügbar ist
    #  (DNSKEY TTL auslaufen lassen)

    # Neuen DNSKEY der Domain in der TLD eintragen
    #  http://whois.test/

    # TESTEN

    # Größere TTL abwarten:
    # * DS des Parent ODER
    # * Maximum Zone TTL eigener Domain

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
        sig-validity-interval 7 4;
        # 7 Tage Signatur-Zeitrraum
        # Resigning 4 Tage vor Expiration
        # -> Signatur-Zeitfenster: 3 Tage
    };
    ```

1. Zonen-Konfiguration anpassen
    ```
    zone "domain2.tld." IN {
        type master;
        file "/etc/bind/zones/domain2.tld.zone";
        auto-dnssec maintain;
        inline-signing yes;

        # bei Bedarf 'no' für CSK Schema
        # no == KSK auch als ZSK nutzen
        #update-check-ksk no;

        # für nsupdate von localhost
        #update-policy local;
    };
    ```

1. Zone mit DNSSEC signieren und NSEC3 einrichten
    ```
    rndc reload

    # TESTEN

    rndc sign domain2.tld
    rndc signing -nsec3param 1 0 20 \
    $(openssl rand 4 -hex) domain2.tld

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
1. Time Drift & Signatur-Validierung
1. TTL=0 für Records verwenden - Validierung noch möglich?
1. TTLs auf geringen Wert setzen


## Erweiterung des Setups

1. BIND Inline Signing

1. Bump on Wire Signing mit anderen Teilnehmern einrichten

1. Slave Nameserver für Zonen einrichten (TSIG)



/* vim: set syntax=markdown tabstop=2 expandtab: */
