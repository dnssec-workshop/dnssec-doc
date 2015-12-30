#!/bin/bash
# /etc/bind/scripts/sign-zone.sh
# Resign TLD zone

ZONEFILE_DIR=/etc/bind/zones
KEYFILE_DIR=/etc/bind/keys
RRSIG_VALIDITY="+2h"
RRSIG_JITTER=300

TLD=$1

# Smart zone signing
if [ ! "$(find $KEYFILE_DIR -name "K${TLD}*" -type f)" ]
then
	echo "WARNING: No DNSSEC keys found for zone ${TLD}. key dir $KEYFILE_DIR - signing skipped." >&2
	exit 2
fi

dnssec-signzone -S -K $KEYFILE_DIR -d $KEYFILE_DIR -e $RRSIG_VALIDITY -j $RRSIG_JITTER -r /dev/urandom -a -3 $(openssl rand 4 -hex) -H 15 -A -o ${TLD}. $ZONEFILE_DIR/${TLD}.zone
exit $?
