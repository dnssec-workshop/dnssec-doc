\$TTL $ZONE_TTL
pl.		SOA	a-dns.pl. dnssec.arminpech.de. ( $ZONE_SERIAL 1800 900 1814400 1800 )

pl.		NS	a-dns.pl.
pl.		NS	b-dns.pl.

a-dns.pl.	A	10.20.2.1
b-dns.pl.	A	10.20.2.2

$ZONE_RECORDS
