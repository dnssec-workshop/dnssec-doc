\$TTL $ZONE_TTL
net.		SOA	a.gtld.net. dnssec.arminpech.net. ( $ZONE_SERIAL 1800 900 1814400 1800 )

net.		NS	a.gtld.net.
net.		NS	b.gtld.net.

a.gtld.net.	A	10.20.2.1
b.gtld.net.	A	10.20.2.2

$ZONE_RECORDS
