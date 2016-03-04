#!/bin/bash
# /etc/bind/scripts/auto-signing.sh <zone_dir> <search domains> <force_zone_serial>
# Sign all zones in directory

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ZONEFILE_DIR=${ZONEFILE_DIR:-$1}

SEARCH_DOMAINS=${SEARCH_DOMAINS:-"$2"}
[ "$SEARCH_DOMAINS" ] && SEARCH_DOMAINS=$(echo "$SEARCH_DOMAINS" | sed "s/ /\\\|/g")

FORCE_SERIAL=${FORCE_SERIAL:-$3}

find $ZONEFILE_DIR -name "*.zone" -printf "%f\n" | sed "s/.zone//" | grep "$SEARCH_DOMAINS" | while read zone
do
	$(dirname $0)/sign-zone.sh $zone "$FORCE_SERIAL" -z
done

rndc reload
