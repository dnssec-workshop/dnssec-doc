#!/bin/bash
# /etc/bind/scripts/auto-signing.sh <zone_dir> <search domains> <force_zone_serial>
# Sign all zones in directory

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ZONEFILE_DIR=${ZONEFILE_DIR:-$1}

SEARCH_DOMAINS=${SEARCH_DOMAINS:-"$2"}
[ "$SEARCH_DOMAINS" ] && SEARCH_DOMAINS=$(echo "$SEARCH_DOMAINS" | sed "s/ /\\\|/g")

FORCE_SERIAL=${FORCE_SERIAL:-$3}

# TODO: read options from domain list file
find $ZONEFILE_DIR -name "*.zone" ! -name "hint.zone" -printf "%f\n" | sed "s/.zone//" | grep "$SEARCH_DOMAINS" | while read zone
do
	echo "== $zone =="
	$(dirname $0)/sign-zone.sh $zone "$FORCE_SERIAL" -z
done

# Bump serial of other zones
find $ZONEFILE_DIR -name "*.zone" ! -name "hint.zone" -printf "%f\n" | sed "s/.zone//" | grep -v "$SEARCH_DOMAINS" | while read zone
do
	echo "== $zone =="
	curr_serial=$(cat $ZONEFILE_DIR/${zone}.zone | tr -d '\n' | grep -o 'SOA[[:space:]]\+[^[:space:]]\+[[:space:]]\+[^[:space:]]\+[[:space:]]\+[^[:space:]]\?[[:space:]]\?[0-9]\+\|###DEPLOY_SERIAL###' | grep -o '[0-9]\+$\|###DEPLOY_SERIAL###$')
	echo "$zone: current serial is $curr_serial"

	if [ "$curr_serial" = "###DEPLOY_SERIAL###" ]
	then
		curr_set_serial=$(($(dig +noall +answer -t SOA $zone @localhost 2>/dev/null | grep SOA | awk '{print $7}')+0))
		FORCE_SERIAL=$(($curr_set_serial+1))
		[ $curr_set_serial -le 0 ] && FORCE_SERIAL=$(date +%Y%m%d%H)
		echo "$zone: forcing serial to $FORCE_SERIAL"
	fi

	# Increment or set serial
	ZONE_SERIAL=${FORCE_SERIAL:-$(($curr_serial+1))}

	# Bump the serial for transfer/notify
	sed -i "s/\(.*[^a-z0-9]\)$curr_serial\([^a-z0-9].*\)/\1${ZONE_SERIAL}\2/i" $ZONEFILE_DIR/${zone}.zone
	echo "$zone: new serial is $ZONE_SERIAL"
done

rndc reload
