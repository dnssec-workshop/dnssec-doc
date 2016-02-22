#!/bin/bash
# /var/www/dnsviz/probe.sh

DOMAIN=$(echo -e "${QUERY_STRING//domain=}" | sed "s/[^A-Za-z0-9\.-]//g")

BIN_DNSVIZ=/usr/local/bin/dnsviz

TRUSTED_KEY_FILE=/etc/trusted-key.key

echo "Content-Type: text/html"
echo ""

if [ ! "$DOMAIN" -o ${#DOMAIN} -lt 4 ]
then
	echo "ERROR: No valid domain specified: '$DOMAIN'"
	exit 1
fi

$BIN_DNSVIZ probe -4 -d 2 -E -p $DOMAIN | $BIN_DNSVIZ graph -t $TRUSTED_KEY_FILE -T html | sed "s@file:///usr/local@@"

#if [ "${PIPESTATUS[0]}" != "0" ]
#then
#	echo "ERROR: dnsviz probe for domain '$DOMAIN' returned code ${PIPESTATUS[0]}"
#	exit 1
#elif [ "${PIPESTATUS[1]}" != "0" ]
#then
#	echo "ERROR: dnsviz graph for domain '$DOMAIN' returned code ${PIPESTATUS[1]}"
#	exit 1
#fi
