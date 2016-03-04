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

# Get serial
curr_serial=$(cat $ZONEFILE_DIR/${DOMAIN_FILE}zone | tr -d '\n' | grep -o 'SOA[[:space:]]\+[^[:space:]]\+[[:space:]]\+[^[:space:]]\+[[:space:]]\+[^[:space:]]\?[[:space:]]\?[0-9]\+\|###DEPLOY_SERIAL###' | grep -o '[0-9]\+$\|###DEPLOY_SERIAL###$')
echo "$DOMAIN: current serial is $curr_serial"

if [ "$curr_serial" = "###DEPLOY_SERIAL###" ]
then
	curr_set_serial=$(($(dig +noall +answer -t SOA $DOMAIN @localhost 2>/dev/null | grep SOA | awk '{print $7}')+0))
	FORCE_SERIAL=$(($curr_set_serial+1))
	[ $curr_set_serial -le 0 ] && FORCE_SERIAL=$(date +%Y%m%d%H)
	echo "$DOMAIN: forcing serial to $FORCE_SERIAL"
fi

# Increment or set serial
ZONE_SERIAL=${FORCE_SERIAL:-$(($curr_serial+1))}

# Additional signing options
SIGNING_OPTIONS=${SIGNING_OPTIONS:-$3}

# Smart zone signing
if [ ! "$(find $KEYFILE_DIR -name "K${DOMAIN}*" -type f)" ]
then
	echo "WARNING: No DNSSEC keys found for zone '${DOMAIN}' in key dir $KEYFILE_DIR - signing skipped." >&2
	exit 2
fi

# Bump the serial for transfer/notify
sed -i "s/\(.*[^a-z0-9]\)$curr_serial\([^a-z0-9].*\)/\1${ZONE_SERIAL}\2/i" $ZONEFILE_DIR/${DOMAIN_FILE}zone
echo "$DOMAIN: new serial is $ZONE_SERIAL"

# Sign the zone and update NSEC3PARAM
dnssec-signzone -S -K $KEYFILE_DIR -d $KEYFILE_DIR -e $RRSIG_VALIDITY -j $RRSIG_JITTER -r /dev/urandom -a -3 $(openssl rand 4 -hex) -H 15 -A -o ${DOMAIN} $SIGNING_OPTIONS $ZONEFILE_DIR/${DOMAIN_FILE}zone
exit $?
