#!/bin/bash
# /etc/bind/scripts/zone-update.sh [-c|--check] [<tld1 tld2> [<overwrite_soa_serial>]

ZONEFILE_DIR=/etc/bind/zones

RUN_CHECK=0
if [ "$1" = "-c" -o "$1" = "--check" ]
then
	shift
	RUN_CHECK=1
fi

ZONES=${1:-"at com de it net nl org pl se"}
FORCE_SERIAL=$2

for tld in $ZONES
do
	$(dirname $0)/update-zone-from-db.sh $tld $FORCE_SERIAL
	$(dirname $0)/sign-zone.sh $tld
	echo
done

if [ $RUN_CHECK -eq 1 ]
then
	for tld in $ZONES
	do
		if [ -e "${ZONEFILE_DIR}/${tld}.zone.signed" ]
		then
			named-checkzone ${tld}. ${ZONEFILE_DIR}/${tld}.zone.signed
		elif [ -e "${ZONEFILE_DIR}/${tld}.zone" ]
		then
			named-checkzone ${tld}. ${ZONEFILE_DIR}/${tld}.zone
		else
			echo "ERROR: Found no zone file for TLD $tld" >&2
		fi
	done
fi
