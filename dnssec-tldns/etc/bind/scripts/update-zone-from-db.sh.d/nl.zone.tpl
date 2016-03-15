\$TTL $ZONE_TTL
nl.		SOA	ns1.dns.nl. dnssec.arminpech.de. ( $ZONE_SERIAL 1800 900 1814400 1800 )

nl.		NS	ns1.dns.nl.
nl.		NS	ns2.dns.nl.

ns1.dns.nl.	A	10.20.2.1
ns2.dns.nl.	A	10.20.2.2

$ZONE_RECORDS
