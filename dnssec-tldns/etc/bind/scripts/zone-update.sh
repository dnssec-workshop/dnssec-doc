#!/bin/bash
# /etc/bind/scripts/zone-update.sh

ZONES=${1:-"at com de it net nl org pl se"}

for tld in $ZONES
do
	$(dirname $0)/update-zone-from-db.sh $tld
	$(dirname $0)/sign-zone.sh $tld
	echo
done
