#!/bin/bash
# /var/www/dnsviz/probe.sh

DOMAIN=$(echo -e "${QUERY_STRING//domain=}" | sed "s/[^A-Za-z0-9\._-]//g")

BIN_DNSVIZ=/usr/local/bin/dnsviz

TRUSTED_KEY_FILE=/etc/trusted-key.key

echo "Content-Type: text/html"
echo ""

if [ ! "$DOMAIN" -o ${#DOMAIN} -lt 1 ]
then
	echo "ERROR: No valid domain specified: '$DOMAIN'"
	exit 1
fi

$BIN_DNSVIZ probe -4 -d 2 -t 8 -E -s 127.0.0.2 $DOMAIN | $BIN_DNSVIZ graph -t $TRUSTED_KEY_FILE -T html | sed "s@file:///usr/local@@"
