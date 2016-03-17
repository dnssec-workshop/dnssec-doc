#!/bin/bash
# /etc/bind/scripts/update-zone-from-db.sh <TLD>
# Update SLD zones from database

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

DB_HOST=localhost
DB_PORT=3306
DB_USERNAME=root
DB_PASSWORD=root
DB_NAME=sld
DB_TABLE=domains

TEMPLATE_DIR=$(dirname $0)/$(basename $0).d
ZONEFILE_DIR=/etc/bind/zones

ZONE_TTL=1800

TLD=$1
[ "${TLD: -1}" = "." ] && TLD=${TLD:0:-1}

# get current records from database
DNS_RECORDS="$(mysql --batch --skip-column-names -u$DB_USERNAME -p$DB_PASSWORD $DB_NAME -e "
-- get authoritative nameservers for registered domains of TLD
select ifnull(concat(name, '. NS ', nserver1_name, '.'), '') from $DB_TABLE where not nserver1_name = '' and substring_index(name, '.', -1) = '$TLD';
select ifnull(concat(name, '. NS ', nserver2_name, '.'), '') from $DB_TABLE where not nserver2_name = '' and substring_index(name, '.', -1) = '$TLD';
select ifnull(concat(name, '. NS ', nserver3_name, '.'), '') from $DB_TABLE where not nserver3_name = '' and substring_index(name, '.', -1) = '$TLD';
-- identify which SLD nameservers need to glued in TLD zone
select ifnull(concat(nserver1_name, '. A ', nserver1_ip), '') from $DB_TABLE where not ( nserver1_name = '' or nserver1_name is null ) and not ( nserver1_ip = '' or nserver1_ip is null ) and instr(nserver1_name, name) > 0 and substring_index(name, '.', -1) = '$TLD';
select ifnull(concat(nserver2_name, '. A ', nserver2_ip), '') from $DB_TABLE where not ( nserver2_name = '' or nserver2_name is null ) and not ( nserver2_ip = '' or nserver2_ip is null ) and instr(nserver2_name, name) > 0 and substring_index(name, '.', -1) = '$TLD';
select ifnull(concat(nserver3_name, '. A ', nserver3_ip), '') from $DB_TABLE where not ( nserver3_name = '' or nserver3_name is null ) and not ( nserver3_ip = '' or nserver3_ip is null ) and instr(nserver3_name, name) > 0 and substring_index(name, '.', -1) = '$TLD';
")"

DNS_DS_RECORDS="$(mysql --batch --skip-column-names -u$DB_USERNAME -p$DB_PASSWORD $DB_NAME -e "
select ifnull(concat(name, '. IN DNSKEY ', dnskey1_flags, ' 3 ', dnskey1_algo, ' ', dnskey1_key), '') from $DB_TABLE where substring_index(name, '.', -1) = '$TLD' and dnskey1_flags > 0 and dnskey1_algo > 0 and not ( dnskey1_key = '' or dnskey1_key is null );
select ifnull(concat(name, '. IN DNSKEY ', dnskey2_flags, ' 3 ', dnskey2_algo, ' ', dnskey2_key), '') from $DB_TABLE where substring_index(name, '.', -1) = '$TLD' and dnskey2_flags > 0 and dnskey2_algo > 0 and not ( dnskey2_key = '' or dnskey2_key is null );
" | $(dirname $0)/dnskey2ds.pl)"

ZONE_SERIAL=$(date +%s)
ZONE_RECORDS="$(echo -e "$DNS_RECORDS\n$DNS_DS_RECORDS" | grep -v "^\s*$\|^\s*;")"

if [ ${PIPESTATUS[0]} -ne 0 -o ! "$ZONE_RECORDS" ]
then
	echo "ERROR: Failed to read any records for zone ${TLD}. from database." >&2
	exit ${PIPESTATUS[0]}
fi

eval "cat <<EOF >${ZONEFILE_DIR}/${TLD}.zone
$(< $TEMPLATE_DIR/${TLD}.zone.tpl)
EOF"

awk '{print $1}' ${ZONEFILE_DIR}/${TLD}.zone | grep -io "[a-z-]\+\.[a-z]\+\.$" | sort -u

exit $?
