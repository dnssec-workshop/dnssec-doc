\$TTL $ZONE_TTL
de.		SOA	a.nic.de. dnssec.arminpech.de. ( $ZONE_SERIAL 1800 900 1814400 1800 )

de.		NS	a.nic.de.
de.		NS	b.denic.de.

a.nic.de.	A	10.20.2.1
b.denic.de.	A	10.20.2.2

denic.de.       A       10.20.2.23
nic.de.         A       10.20.2.23

whois.de        A       10.20.2.22

$ZONE_RECORDS
