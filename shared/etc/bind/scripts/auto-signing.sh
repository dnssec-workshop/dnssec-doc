#!/bin/bash
# /etc/bind/scripts/auto-signing.sh <zone_dir> <search domains>
# Sign all zones in directory

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ZONEFILE_DIR=${ZONEFILE_DIR:-$1}

SEARCH_DOMAINS=${SEARCH_DOMAINS:-"$2"}
[ "$SEARCH_DOMAINS" ] && SEARCH_DOMAINS=$(echo "$SEARCH_DOMAINS" | sed "s/ /\\\|/g")

grep "file.*\.zone" /etc/bind/named.conf | grep -v "hint.zone" | awk -F'"' '{print $2,$4}' | while read file signing_options
do
	if echo "$file" | grep -q "\.signed"
	then
		# Resign DNSSEC zone
		$(dirname $0)/sign-zone.sh $(basename $file .zone.signed) "$signing_options"

	else
		# Bump the serial of unsigned zones
		perl -pi -e "s/(.*\s+SOA\s+[^\s]+\s+[^\s]+[\s\(]*)\s+[0-9]+(.*)/\$1 $(date +%s)\$2/m" $file
	fi
done

rndc reload
