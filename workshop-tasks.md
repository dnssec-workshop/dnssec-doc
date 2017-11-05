## Informationen und Setup des Workshop

Die Workshop-Umgebung besteht aus folgenden Systemen:

* dnssec-rootns-a
  * `10.20.1.1/16`
  * Master Root-Nameserver a.root-servers.test.

* dnssec-rootns-b
  * `10.20.1.2/16`
  * Slave Root-Nameserver b.root-servers.test.

* dnssec-tldns-a
  * `10.20.2.1/16`
  * Master Nameserver für einen Teil der TLDs
  * whois Service
  * Domain Registrar Interface

* dnssec-tldns-b
  * `10.20.2.2/16`
  * Slave Nameserver für einen Teil der TLDs

* dnssec-sldns-a
  * `10.20.4.1/16`
  * Master Nameserver für SLDs mit DNSSEC-Beispielen

* dnssec-sldns-b
  * `10.20.4.2/16`
  * Slave Nameserver für SLDs

* dnssec-resolver
  * `10.20.8.1/16`
  * Nameserver als Resolver für Workshop-Umgebung
  * dnsviz Analyse-Tool + Non-Caching Nameserver
  * Git-Repository mit den Workshop-Informationen und Dateien
  * Webserver mit Files und Informationen inkl. Wiki

* Verfügbare TLDs:
  * `at.`, `com.`, `de.`, `it.`, `net.`, `nl.`, `org.`, `pl.`, `se.`, `test.`
  * `test.`: Domain für interne Workshop-Services
  * `it.`: keine Signierung mit DNSSEC
  * `org.`: DS-Records nicht in Root-Servern eingetragen

* Netzwerkumgebung einrichten
  * Per Ethernet am Switch anschließen
    * **Port-Nummer merken** => `${NSID}`
  * Netz: `10.20.0.0/16`
  * Gateway: `10.20.0.1`
  * Teilnehmer-Netz: `10.20.42.0/16`
    ```
    ifconfig eth0 10.20.42.${NSID}/16
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

  * Workshop Anleitungen: http://doc.test/workshop-tasks.html

  * Default Router / ggf. Gateway ins Internet

  * Registrierung von Domains

  * Whois Service über Domains

  * DNSViz Debugging

  * GitWeb mit relevanten Daten zum Workshop

* Mitmachen per Docker VM

## Umgebung erkunden

Nachdem Du nun im Workshop-Netz bist, können wir einige Tests vornehmen und die Umgebung erkunden.

1. Login auf die Docker VM
    ```
    ssh root@10.20.33.${NSID}

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

    dig +noall +answer +multi \
        -t DNSKEY . @10.20.1.1 | \
        awk '/DNSKEY 257/,/; KSK;/ {print}' \
        > /etc/trusted-key.key
    ```

1. Prüfe die Chain of Trust für die Domain `task-sigchase.de.`
    ```
    drill -S -k /etc/trusted-key.key task-sigchase.de
    # dig +sigchase +topdown task-sigchase.de.
    ```

1. Die visualisierte Prüfung kann auch per DNSViz erfolgen:
    * http://dnsviz.test/graph.sh?domain=task-sigchase.de


## Eigene Domain anlegen

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
        * Hier müssen Glue-Records mit der IP Deines Systems oder Containers eingetragen werden!
            * `ns1.$DOMAIN_TLD` -- `10.20.33.X`
            * `ns2.$DOMAIN_TLD` -- `10.20.33.X`
        * Die Nameserver von `$DOMAIN_TLD` können später als NS-Records für weitere Domains (ohne Glues) verwendet werden.

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
    chown bind: /etc/bind/zones /var/cache/bind /var/log/named || \
    chown named: /etc/bind/zones /var/cache/bind /var/log/named
    ```

    * Config Files aus `dnssec-attendee/` kopieren
       * `/etc/bind/named.conf`
       ```
       curl 'http://gitweb.test/gitweb.cgi?p=dnssec-data/.git;a=blob_plain;f=dnssec-attendee/etc/bind/named.conf' >/etc/bind/named.conf
       ```

       * `/etc/bind/zones/hint.zone`
       ```
       curl 'http://gitweb.test/gitweb.cgi?p=dnssec-data/.git;a=blob_plain;f=shared/etc/bind/zones/hint.zone' >/etc/bind/zones/hint.zone
       ```

       * `/etc/bind/zones/hint.zone`
       ```
       curl 'http://gitweb.test/gitweb.cgi?p=dnssec-data/.git;a=blob_plain;f=dnssec-attendee/etc/bind/zones/template.zone' > /etc/bind/zones/template.zone
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
    options {
        edns yes; # default
        edns-udp-size 4096; # default

        dnssec-enable yes;
        key-directory "/etc/bind/keys";
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
    mkdir -p $KEY_DIR

    dnssec-keygen -K $KEY_DIR -n ZONE -f KSK \
      -a ECDSAP256SHA256 -r /dev/urandom \
      -L 86400 -P now -A now $DOMAIN_TLD

    dnssec-keygen -K $KEY_DIR -n ZONE \
      -a ECDSAP256SHA256 -r /dev/urandom \
      -L 86400 -P now -A now $DOMAIN_TLD

    # BIND muss Private Keys lesen
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

    dig +dnssec -t DNSKEY \
      test-notfound.$DOMAIN_TLD. @localhost
    ```

1. NSEC3 für die Zone einrichten
    ```
    rndc signing -nsec3param 1 0 20 \
      $(openssl rand 4 -hex) $DOMAIN_TLD
    ```

    ```
    dig +dnssec -t DNSKEY \
      test-notfound.$DOMAIN_TLD. @localhost
    ```

1. Zustand der signierten Zonen prüfen
    * Keys anzeigen lassen
    ```
    rndc signing -list $DOMAIN_TLD.
    ```

    * Manuelle Prüfung
    ```
    dig +dnssec +multi -t DNSKEY \
        $DOMAIN_TLD. @localhost
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
      * DNSSEC Key 1 algorithm_id: 13
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

    * Zum Nachbarn verbinden
      ```
      host ssh.fellow.next

      ssh -o UserKnownHostsFile=/dev/null root@ssh.fellow.next
      ssh -o UserKnownHostsFile=/dev/null -o VerifyHostKeyDNS=Yes -v ssh.fellow.next
      ```


### DANE für Mailing

1. SSL-Zertifikate für Postfix generieren
    ```
    cd /etc/postfix

    openssl req -new -x509 -nodes \
      -out server.pem -keyout server.pem \
      -subj "/C=DE/ST=Country/L=City/O=DNSSEC/OU=Workshop/CN=mail.$DOMAIN_TLD"

    openssl gendh 1024 >> server.pem
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
    echo | openssl s_client -showcerts -connect mail.$DOMAIN_TLD:465
    ```

    ```
    ldns-dane verify -S -k /etc/trusted-key.key \
      mail.$DOMAIN_TLD 465
    ```


## Key Management

1. Führe einen ZSK Rollover (per Pre-Publish) ohne Interaktion mit der Parent TLD aus
    ```
    KEY_DIR=/etc/bind/keys

    # Neuen ZSK generieren und in Zone publizieren
    dnssec-keygen -K $KEY_DIR -n ZONE \
      -a ECDSAP256SHA256 -r /dev/urandom \
      -L 86400 -P now -A +1h $DOMAIN_TLD

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
      -a ECDSAP256SHA256 -r /dev/urandom \
      -L 86400 -P now -A now $DOMAIN_TLD

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
    dig +dnssec task-sigchase.de. @localhost
    dig +dnssec dnssec-failed.net. @localhost
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
       curl 'http://gitweb.test/gitweb.cgi?p=dnssec-data/.git;a=blob_plain;f=shared/etc/bind/managed.keys' >/etc/bind/managed.keys
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
    dig +dnssec task-sigchase.de. @localhost

    dig +dnssec dnssec-failed.net. @localhost
    less /var/log/named/default.log

    drill -S -k /etc/trusted-key.key \
      dnssec-failed.net.
    ```


## Weitere DNSSEC Informationen prüfen

1. Signing Schemata vergleichen
    * task-sigchase.de -- KSK & ZSK
    * dnsprovi.de -- Combined Signing Key
    * task-rollover.de -- Backup KSK

1. Zone Expire VS. Signatur-Zeitraum

1. Zone Expire & NSEC Signatur-Zeitraum

1. NSEC(3) Zone Walking
    * https://josefsson.org/walker/
    * http://doc.test/nsec-walker/
    * `walker -x task-walker.de`


## Fehler provozieren und beheben

1. Falschen DS im Parent publizieren
1. KSK oder ZSK löschen/deaktivieren
1. Time Drift & Signatur-Validierung
1. TCP-Anfragen unterbinden
1. Signaturen auslaufen lassen
    * `dnssec-failed.net`


## Erweiterung des Setups

1. Bump on Wire Signing mit anderen Teilnehmern einrichten
    * Master Zone soll nicht mit DNSSEC signiert sein (neue Zone anlegen)
    * Slave Zone analog zu DNSSEC Master Zone konfigurieren

1. TSIG zwischen Master und Slave Nameservern für Zonen einrichten
    1. Master

      ```
      dnssec-keygen -n HOST -a HMAC-SHA512 -b 512 tsig
      grep Key: Ktsig.+*.private
      ```
  
      `/etc/bind/named.conf`
      ```
      key "tsig" {
                algorithm hmac-sha512;
                secret "<private_key>";
      };
  
      server <slave> {
              keys { tsig; };
      };
  
      zone "<zone>" {
        ...
        allow-transfer { key tsig; };
      };
      ```

      ```
      rndc reload
      ```

    1. Slave

      `/etc/bind/named.conf`
      ```
      key "tsig" {
                algorithm hmac-sha512;
                secret "<private_key>";
      };
  
      server <master {
              keys { tsig; };
      };
      ```

      ```
      rndc reload
      ```

1. Rollover eines DNSSEC Signatur Algorithmus



/* vim: set syntax=markdown tabstop=2 expandtab: */
