\$TTL $ZONE_TTL
at.		SOA	a.ns.at. dnssec.arminpech.de. ( $ZONE_SERIAL 1800 900 1814400 1800 )

at.		NS	a.ns.at.
at.		NS	b.ns.at.

a.ns.at.	A	10.20.2.1
b.ns.at.	A	10.20.2.2

$ZONE_RECORDS
