#!/bin/bash
# /etc/bind/scripts/sign-zone.sh <TLD> <force_serial>
# Resign TLD zone

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ZONEFILE_DIR=/etc/bind/zones
KEYFILE_DIR=/etc/bind/keys
RRSIG_VALIDITY=${RRSIG_VALIDITY:-"+4h"}
RRSIG_JITTER=${RRSIG_JITTER:-"300"}

TLD=$1
[ "${TLD: -1}" != "." ] && TLD=${TLD}.
TLD_FILE=$TLD
[ "$TLD" = "." ] && TLD_FILE="root."

FORCE_SERIAL=$2

# Increment or set serial
ZONE_SERIAL=${FORCE_SERIAL:-$(($(dig +noall +answer -t SOA $TLD @localhost | awk '{print $7}' 2>/dev/null)+1))}

# Additional signing options
SIGNING_OPTIONS=${SIGNING_OPTIONS:-$3}

# Smart zone signing
if [ ! "$(find $KEYFILE_DIR -name "K${TLD}*" -type f)" ]
then
	echo "WARNING: No DNSSEC keys found for zone '${TLD}' in key dir $KEYFILE_DIR - signing skipped." >&2
	exit 2
fi

# Sign the zone and update NSEC3PARAM
dnssec-signzone -S -K $KEYFILE_DIR -d $KEYFILE_DIR -e $RRSIG_VALIDITY -j $RRSIG_JITTER -r /dev/urandom -a -3 $(openssl rand 4 -hex) -H 15 -A -L $ZONE_SERIAL -N increment -o ${TLD} $SIGNING_OPTIONS $ZONEFILE_DIR/${TLD_FILE}zone
exit $?
