# Informationen zur Workshop Umgebung

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

* Verfügbare Services:
  * Default Router / ggf. Gateway ins Internet
    ```
    route add -net default gw 10.20.0.1
    ```

  * Registrierung von Domains: http://nic.test/
  * Whois Service über Domains: whois.test
    ```
    whois -h whois.test <domain_name>
    ```

  * DNS-Resolver mit DNSSEC-Support: resolver.test / 10.20.8.1
    ```
    dig -t ANY test. @resolver.test.
    ```

  * DNSViz Debugging: http://dnsviz.test/

/* vim: set syntax=markdown tabstop=2 expandtab: */
