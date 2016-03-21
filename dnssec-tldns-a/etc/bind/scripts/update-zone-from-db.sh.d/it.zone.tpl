\$TTL $ZONE_TTL
it.		SOA	a.dns.it. dnssec.arminpech.it. ( $ZONE_SERIAL 1800 900 1814400 1800 )

it.		NS	a.dns.it.
it.		NS	b.dns.it.

a.dns.it.	A	10.20.2.1
b.dns.it.	A	10.20.2.2

$ZONE_RECORDS
