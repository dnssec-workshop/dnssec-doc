\$TTL $ZONE_TTL
se.		SOA	a.ns.se. dnssec.arminpech.de. ( $ZONE_SERIAL 1800 900 1814400 1800 )

se.		NS	a.ns.se.
se.		NS	b.ns.se.

a.ns.se.	A	10.20.2.1
b.ns.se.	A	10.20.2.2

$ZONE_RECORDS
