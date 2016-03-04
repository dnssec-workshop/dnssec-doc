#!/bin/bash
# /etc/bind/scripts/sign-zone.sh <DOMAIN> <force_serial>
# Resign DOMAIN zone

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ZONEFILE_DIR=/etc/bind/zones
KEYFILE_DIR=/etc/bind/keys
RRSIG_VALIDITY=${RRSIG_VALIDITY:-"+4h"}
RRSIG_JITTER=${RRSIG_JITTER:-"300"}

DOMAIN=$1
[ "${DOMAIN: -1}" != "." ] && DOMAIN=${DOMAIN}.
DOMAIN_FILE=$DOMAIN
[ "$DOMAIN" = "." ] && DOMAIN_FILE="root."

FORCE_SERIAL=$2

# Increment or set serial
ZONE_SERIAL=${FORCE_SERIAL:-$(($(cat $ZONEFILE_DIR/${DOMAIN_FILE}zone | tr -d '\n' | grep -o 'SOA[[:space:]]\+[^[:space:]]\+[[:space:]]\+[^[:space:]]\+[[:space:]]\+[^[:space:]]\?[[:space:]]\?[0-9]\+' | grep -o '[0-9]\+$')+1))}

# Additional signing options
SIGNING_OPTIONS=${SIGNING_OPTIONS:-$3}

# Smart zone signing
if [ ! "$(find $KEYFILE_DIR -name "K${DOMAIN}*" -type f)" ]
then
	echo "WARNING: No DNSSEC keys found for zone '${DOMAIN}' in key dir $KEYFILE_DIR - signing skipped." >&2
	exit 2
fi

# Bump the serial for transfer/notify
sed -i "s/\(.*[^a-z0-9]\)$ZONE_SERIAL\([^a-z0-9].*\)/\132\2/i" $ZONEFILE_DIR/${DOMAIN_FILE}zone
# Sign the zone and update NSEC3PARAM
dnssec-signzone -S -K $KEYFILE_DIR -d $KEYFILE_DIR -e $RRSIG_VALIDITY -j $RRSIG_JITTER -r /dev/urandom -a -3 $(openssl rand 4 -hex) -H 15 -A -o ${DOMAIN} $SIGNING_OPTIONS $ZONEFILE_DIR/${DOMAIN_FILE}zone
exit $?
