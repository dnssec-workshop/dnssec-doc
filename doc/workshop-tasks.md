## Informationen und Setup des Workshop

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
  * `at.`, `com.`, `de.`, `it.`, `net.`, `nl.`, `org.`, `pl.`, `se.`, `test.`
  * `test.`: Domain für interne Workshop-Services
  * `it.`: keine Signierung mit DNSSEC
  * `org.`: DS-Records nicht in Root-Servern eingetragen

* Netzwerkumgebung
  * Netz: 10.20.0.0/16
  * Gateway: 10.20.0.1
  * Du bekommst Dein eigenes /24 Subnetz.
  * Subnetz von 50 bis 255 -- 10.20.${NETID}.1/16
    ```
    ifconfig eth0 10.20.X.1/16
    route add -net default gw 10.20.0.1
    ```

  * DHCP-Client ausgeschaltet?

  * Konfiguriere Deinen lokalen Resolver für die Nutzung der Workshop Umgebung:
    ```
    echo 'nameserver 10.20.8.1' >/etc/resolv.conf
    ```

      * Auf Deinem eigenen Rechner brauchst Du ggf. Host-Einträge, wenn die Resolver-Konfiguration nicht angepasst ist
        ```
        cp -aH /etc/hosts /etc/hosts.$(date +%Y%m%d_%H%M)

        cat <<EOF >>/etc/hosts

        # DNSSEC Workshop CLT2016
        10.20.2.1 whois.test nic.test
        10.20.8.1 dnsviz.test resolver.test gitweb.test doc.test
        EOF
        ```

* Verfügbare Services:

  * DNS-Resolver mit DNSSEC-Support:

    `resolver.test` / `10.20.8.1`
    ```
    dig -t ANY test. @10.20.8.1
    ```

  * Workshop Anleitungen: http://doc.test/

  * Default Router / ggf. Gateway ins Internet

  * Registrierung von Domains

  * Whois Service über Domains

  * DNSViz Debugging

  * GitWeb mit relevanten Daten zum Workshop

* Mitmachen:
  * **Empfohlen: Docker VM -- Wer will?**
  * Eigenes Gerät

* **Hinweis: Was wir hier machen ist NICHT sicher und sind KEINE BEst Practise!**

## Umgebung erkunden

Nachdem Du nun im Workshop-Netz bist, können wir einige Tests vornehmen und die Umgebung erkunden.

1. Login auf die Docker VM
    ```
    ssh root@10.20.44.X

    # Passwort: root
    ```

1. Nameserver der Root-Zone anzeigen
    ```
    dig -t NS .
    ```

1. Rekursive Anfragen ab den Root-Servern herunter bis Domain `task-trace.de.` ausführen
    ```
    dig +trace +nodnssec task-trace.de.
    ```

1. Whois Informationen der Doamin `task-whois.de.` abfragen
    ```
    whois -h whois.test task-whois.de
    ```


## DNSSEC Informationen abfragen

Jetzt können wir die Umgebung nach DNSSEC Informationen durchsuchen.

1. Zeige die DNSSEC Records der TLD `de.` an.
    ```
    dig +dnssec +multiline -t DNSKEY de.
    ```

    * Unterschiede KSK (257) und ZSK (256)
    * Key Typ: 3 (DNSSEC)
    * Algorithmus: 8 (RSA SHA-256)
    * Key ID: Eindeutige Identifikation möglich
    * Wo finden wir die DNSSEC Key IDs wieder?
    * Sind die Signaturen aktuell und vollständig?

1. Wie wird die TLD `de.` durch die Root-Zone authentifiziert?
    ```
    dig -t DS de.
    ```

    * Welchen DNSKEY Typ referenziert der DS-Records für `de.`?

1. Ist die Domain `task-sigchase.de.` mit DNSSEC signiert?
    ```
    dig -t DNSKEY task-sigchase.de.
    ```

1. Richte den DNSKEY KSK der Root-Nameserver für die Authentifizierung der Records ein:
    * **Nicht in Docker VMs notwendig**
    ```
    cp -aH /etc/trusted-key.key \
           /etc/trusted-key.key.$(date +%Y%m%d_%H%M)

    dig +noall +answer +multi -t DNSKEY . @10.20.1.1 | \
      awk '/DNSKEY 257/,/; KSK;/ {print}' > /etc/trusted-key.key
    ```

1. Prüfe die Chain of Trust für die Domain `task-sigchase.de.`
    ```
    drill -S -k /etc/trusted-key.key task-sigchase.de
    # dig +sigchase +topdown task-sigchase.de.
    ```

1. Die visualisierte Prüfung kann auch per DNSViz erfolgen:
    * http://dnsviz.test/graph.sh?domain=task-sigchase.de


## Eigene Domain anlegen

1. Funktioniert der Bind Restart? -- Fix für Docker VMs
    ```
    rndc reload
    /etc/init.d/bind9 restart
    ```

1. Wähle einen Domainnamen für die weiteren Schritte
    ```
    export DOMAIN_TLD=meindomainname.de
    ```

1. Lass Dir die aktuell registierten Domains anzeigen:
    * Registar-Interface http://whois.test/ aufrufen

1. Lege Dir über das Registrar-Interface eine Domain an:
    * http://whois.test/edit
    * `$DOMAIN_TLD`
        * Verwaltung Deiner Nameserver-Umgebung.
        * Hier müssen Glue-Records eingetragen werden!
            * `ns1.$DOMAIN_TLD` -- `10.20.44.X`
            * `ns2.$DOMAIN_TLD` -- `10.20.44.X`
        * Die Nameserver von `$DOMAIN_TLD` können als NS-Records für weitere Domains (ohne Glues) verwendet werden.

1. Prüfe die Registrierung per whois.
    ```
    whois -h whois.test $DOMAIN_TLD
    ```

1. Lege Deine Konfiguration für BIND an:
    * **Nicht in Docker VMs notwendig**
    * Umgebung einrichten
    ```
    cp -aH /etc/bind /etc/bind.$(date +%Y%m%d_%H%M)
    cp -aH /var/cache/bind /var/cache/bind.$(date +%Y%m%d_%H%M)
    cp -aH /var/log/named /var/log/named.$(date +%Y%m%d_%H%M)

    rm -rI /etc/bind

    mkdir -p /etc/bind/zones /var/cache/bind /var/log/named
    chown bind: /var/cache/bind /var/log/named || \
    chown named: /var/cache/bind /var/log/named
    ```

    * Config Files aus `dnssec-attendee/` kopieren
       * `/etc/bind/named.conf`
       ```
       curl 'http://gitweb.test/gitweb.cgi?p=dnssec-workshop/.git;a=blob_plain;f=dnssec-attendee/etc/bind/named.conf' >/etc/bind/named.conf
       ```

       * `/etc/bind/zones/hint.zone`
       ```
       curl 'http://gitweb.test/gitweb.cgi?p=dnssec-workshop/.git;a=blob_plain;f=shared/etc/bind/zones/hint.zone' >/etc/bind/zones/hint.zone
       ```

       * `/etc/bind/zones/hint.zone`
       ```
       curl 'http://gitweb.test/gitweb.cgi?p=dnssec-workshop/.git;a=blob_plain;f=dnssec-attendee/etc/bind/zones/template.zone' > /etc/bind/zones/template.zone
       ```

1. Erstelle Deine Zonen-Konfiguration:
    ```
    cp /etc/bind/zones/template.zone \
    /etc/bind/zones/$DOMAIN_TLD.zone

    sed -i "s/domain.tld./$DOMAIN_TLD./g" \
    /etc/bind/zones/$DOMAIN_TLD.zone
    ```

    * Zone-File von `$DOMAIN_TLD` editieren

      `/etc/bind/zones/$DOMAIN_TLD.zone`

       * Domain-Namen anpassen
       * NS Glue Records eintragen
       * A-Records für Glue Nameserver zeigen auf eigene IP
       * A-Record auf beliebige IP
       * CNAME auf andere Zone

    * Nameserver Konfiguration

      `/etc/bind/named.conf`
      ```
      zone "$DOMAIN_TLD." {
             type master;
             file "/etc/bind/zones/$DOMAIN_TLD.zone";
      };
      ```

1. Nameserver starten und prüfen
    ```
    named-checkconf -z

    rndc reload

    less /var/log/named/default.log
    ```

1. Setup prüfen
    ```
    dig -t SOA $DOMAIN_TLD. @localhost
    dig -t NS $DOMAIN_TLD. @localhost
    ```

1. Ist Deine Domain im TLD Nameserver eingetragen?
    ```
    dig +trace +nodnssec -t NS $DOMAIN_TLD.
    ```

1. Delegation visualisieren:
    * http://dnsviz.test/graph.sh?domain=$DOMAIN_TLD


## DNSSEC für Domain einrichten

1. Basis-Konfiguration im BIND vornehmen
    * `/etc/bind/named.conf`
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

    * Konfiguration laden
    ```
    named-checkconf -z
    rndc reload
    ```

1. DNSSEC Keys für Zonen anlegen
    ```
    KEY_DIR=/etc/bind/keys
    mkdir $KEY_DIR

    dnssec-keygen -K $KEY_DIR -n ZONE -3 -f KSK \
    -a RSASHA256 -b 2048 -r /dev/urandom -L 300 \
    -P now -A now $DOMAIN_TLD

    dnssec-keygen -K $KEY_DIR -n ZONE -3 \
    -a RSASHA256 -b 1024 -r /dev/urandom -L 300 \
    -P now -A now $DOMAIN_TLD

    chown -R bind /etc/bind/keys
    ```

1. DNSKEY Files untersuchen

    * Dateiname
      ```
      ls -l /etc/bind/keys/
      ```

    * private File

    * key File
      ```
      cat /etc/bind/keys/K*.key
      ```

1. Zonen-Konfiguration anpassen
    * `/etc/bind/named.conf`
    ```
    zone "$DOMAIN_TLD." IN {
        type master;
        file "/etc/bind/zones/$DOMAIN_TLD.zone";
        auto-dnssec maintain;
        inline-signing yes;
    };
    ```

    * Konfiguration laden
    ```
    named-checkconf -z
    rndc reload
    ```

    * Zone schon automatisch signiert?
    ```
    less /var/log/named/default.log
    ```

1. Zustand der signierten Zonen prüfen
    ```
    ls -l /etc/bind/zones

    dig -t DNSKEY $DOMAIN_TLD. @localhost

    dig +dnssec -t DNSKEY test-notfound.$DOMAIN_TLD. @localhost
    ```

1. NSEC3 für die Zone einrichten
    ```
    rndc signing -nsec3param 1 0 20 \
    $(openssl rand 4 -hex) $DOMAIN_TLD
    ```

    ```
    dig +dnssec -t DNSKEY test-notfound.$DOMAIN_TLD. @localhost
    ```

1. Zustand der signierten Zonen prüfen
    * Keys anzeigen lassen
    ```
    rndc signing -list $DOMAIN_TLD.
    ```

    * Manuelle Prüfung
    ```
    dig +dnssec +multi -t DNSKEY $DOMAIN_TLD. @localhost
    ```

    * Visualisierung

      http://dnsviz.test/graph.sh?domain=$DOMAIN_TLD

1. Publikation des KSK im Parent via SLD Registrar Webinterface
    * KSK anzeigen (Key mit ID 257 finden)
    ```
    cat /etc/bind/keys/K$DOMAIN_TLD.*.key
    ```

    * Whois Update der Domain -- http://whois.test/
      * DNSSEC Key 1 flags: 257
      * DNSSEC Key 1 algorithm_id: 8
      * DNSSEC Key 1 key_data: Key Material in Base64

    * whois Eintrag bzgl. DNSKEY korrekt?
      ```
      whois -h whois.test $DOMAIN_TLD.
      ```

    * DS-Record in TLD publiziert?
      ```
      dig +trace -t DS $DOMAIN_TLD.
      ```

1. Chain of Trust prüfen
    * http://dnsviz.test/
    * per Command Line Tool
    ```
    drill -S -k /etc/trusted-key.key $DOMAIN_TLD.
    # dig +sigchase +topdown $DOMAIN_TLD.
    ```


## DNSSEC nutzen

### SSH

1. Neue Host Keys generieren
    ```
    rm /etc/ssh/ssh_host_*
    ssh-keygen -A 
    ```

1. SSH Fingerprints
    ```
    ssh-keygen -r ssh.$DOMAIN_TLD.
    ```

1. Generierte DNS-Records in Zone veröffentlichen
    * Unsigniertes Zone-File anpassen
      * A-Record zu `ssh.$DOMAIN_TLD.` mit eigener IP eintragen
      * SSHFP Records eintragen
    * Serial der Zone erhöht?
    * Zone laden
      ```
      rndc reload
      dig -t ANY ssh.$DOMAIN_TLD. @localhost
      ```

1. DNS-Verifikation im SSH-Client aktivieren

    * `/etc/ssh/ssh_config`
      ```
      VerifyHostKeyDNS yes
      ```

    * Zum Nachbarn verbinden
      ```
      host ssh.fellow.next

      ssh <ip_von_ssh.fellow.next>

      ssh ssh.fellow.next
      ```


### DANE für Mailing

1. SSL-Zertifikate für Postfix generieren
    ```
    cd /etc/postfix

    openssl req -new -x509 -nodes \
    -out server.pem -keyout server.pem \
    -subj "/C=DE/ST=Sachsen/L=Chemnitz/O=Linux Tage/OU=2016/CN=mail.$DOMAIN_TLD"

    openssl gendh 512 >> server.pem
    ```

1. DNS-Verifikation im Postfix aktivieren

    * `/etc/postfix/main.cf`
    ```
    smtpd_use_tls = yes
    smtp_tls_security_level = dane
    smtp_dns_support_level = dnssec
    ```

    * `myhostname` und `mydestination` anpassen

    * Konfiguration laden
    ```
    postfix check && postfix reload
    ```

1. TLSA Records der Key Fingerprints generieren
    ```
    openssl x509 -in /etc/postfix/server.pem \
    -outform DER | sha256sum
    ```

1. Daten im DNS veröffentlichen
    * DNS Settings für Mailing definieren
      ```
      mail.DOMAIN.TLD. A <ip>
      DOMAIN.TLD. MX 10 mail.DOMAIN.TLD.
      ```

    * TLSA-Record eintragen
      ```
      _25._tcp.mail.<DOMAIN_TLD>.  IN TLSA 3 0 1 <FINGERPRINT>
      _465._tcp.mail.<DOMAIN_TLD>. IN TLSA 3 0 1 <FINGERPRINT>
      ```

    * Serial erhöht?

    * Zone laden
    ```
    named-checkconf -z
    rndc reload
    ```

1. Verifikation des DANE Setup
    ```
    openssl s_client -connect mail.$DOMAIN_TLD:465
    ```

    ```
    ldns-dane verify -k /etc/trusted-key.key \
    -d mail.$DOMAIN_TLD 465
    ```


## Key Management

1. Führe einen ZSK Rollover (per Pre-Publish) ohne Interaktion mit der Parent TLD aus
    ```
    KEY_DIR=/etc/bind/keys

    # Neuen ZSK generieren und in Zone publizieren
    dnssec-keygen -K $KEY_DIR -n ZONE -3 \
    -a RSASHA256 -b 1024 \
    -r /dev/urandom -L 300 \
    -P now -A +1h $DOMAIN_TLD

    chown -R bind: $KEY_DIR

    rndc sign $DOMAIN_TLD

    rndc signing -list $DOMAIN_TLD

    # Warten bis Key öffentlich verfügbar ist 
    #  (DNSKEY TTL auslaufen lassen)

    # TESTEN

    # Neuen ZSK für das Signieren aktivieren
    dnssec-settime -A now \
    $KEY_DIR/K<name>+<alg>+<id>.key

    # Alten ZSK nach DNSKEY TTL
    #  nicht mehr zum Signieren nehmen
    dnssec-settime -I +330 \
    $KEY_DIR/K<name>+<alg>+<id>.key

    rndc sign $DOMAIN_TLD

    rndc signing -list $DOMAIN_TLD

    # TESTEN

    # Keys und Signaturen prüfen
    # Maximum Zone TTL abwarten

    # TESTEN

    # Alten ZSK raus nehmen
    dnssec-settime -I now -D now \
    $KEY_DIR/K<name>+<alg>+<id>.key

    rndc sign $DOMAIN_TLD

    rndc signing -list $DOMAIN_TLD

    # TESTEN
    ```

1. Führe einen KSK Rollover (per Double Signature) inkl. Interaktion mit dem Parent aus
    ```
    KEY_DIR=/etc/bind/keys

    # Neuen KSK generieren und in Zone publizieren
    # Neuer Key soll ZSKs direkt signieren
    dnssec-keygen -K $KEY_DIR -n ZONE -f KSK \
    -3 -a RSASHA256 -b 2048 \
    -r /dev/urandom -L 300 \
    -P now -A now $DOMAIN_TLD

    chown -R bind: $KEY_DIR

    rndc sign $DOMAIN_TLD

    # TESTEN

    # Warten bis Key öffentlich verfügbar ist
    #  (DNSKEY TTL auslaufen lassen)

    # Neuen DNSKEY der Domain in der TLD eintragen
    #  http://whois.test/

    # TESTEN

    # Größere TTL abwarten:
    # * DS des Parent ODER
    # * DNSKEY der eigenen Zone

    # TESTEN

    # Alten KSK rausnehmen und Zone
    dnssec-settime -D now \
    $KEY_DIR/K<name>+<alg>+<id>.key

    rndc sign $DOMAIN_TLD

    # TESTEN

    # Alten KSK im whois rausnehmen
    ```

1. Rollover zu einem CSK Schema
    ```
    zone [...] {
        update-check-ksk no;
    };
    ```

    ```
    rndc reload
    ```

    ```
    KEY_DIR=/etc/bind/keys

    rndc sign $DOMAIN_TLD

    # TESTEN

    # Maximum Zone TTL abwarten

    # TESTEN

    # Überflüssigen ZSK raus nehmen
    dnssec-settime -D now \
    $KEY_DIR/K<name>+<alg>+<id>.key

    rndc sign $DOMAIN_TLD

    # TESTEN 
    ```


## DNSSEC Validierung im Nameserver einrichten

1. DNSSEC Validierung über lokalen Nameserver versuchen
    ```
    dig +dnssec task-sigchase.de @localhost
    dig +dnssec dnssec-failed.net @localhost
    ```

    * AD-Flag gesetzt?
    * Welche Section liefert DNSSEC-Records?

1. DNSKEY der Root-Server als Trust Anchor einrichten:
    * **Nicht in Docker VM notwendig**
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

1. DNSSEC im Nameserver aktivieren
    /etc/bind/named.conf
    ```
    include "/etc/bind/managed.keys";

    options {
        dnssec-validation yes;
    };
    ```

    ```
    named-checkconf

    rndc reload
    ```

1. DNSSEC Validierung prüfen
    ```
    dig +dnssec task-sigchase.de @localhost

    dig +dnssec dnssec-failed.net @localhost
    less /var/log/named/default.log

    drill -S -k /etc/trusted-key.key dnssec-failed.net
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
    * http://doc.test/nsec-walker/
    * `walker -x task-walker.de`


## Fehler provozieren und beheben

1. TCP-Anfragen unterbinden
1. Signaturen auslaufen lassen
    * `task-failed.net`
1. Falschen DS im Parent publizieren
1. KSK oder ZSK löschen/deaktivieren
1. Time Drift & Signatur-Validierung
1. TTL=0 für Records verwenden - Validierung noch möglich?
1. TTLs auf geringen Wert setzen


## Erweiterung des Setups

1. Bump on Wire Signing mit anderen Teilnehmern einrichten
    * Master Zone soll nicht mit DNSSEC signiert sein (neue Zone anlegen)
    * Slave Zone analog zu DNSSEC Master Zone konfigurieren

1. Slave Nameserver für Zonen einrichten (TSIG)

1. Rollover eines DNSSEC Signatur Algorithmus



/* vim: set syntax=markdown tabstop=2 expandtab: */
