#!/bin/bash
# /etc/bind/scripts/update-zone-from-db.sh <TLD>
# Update SLD zones from database

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
FORCE_SERIAL=$2

# get current serial
ZONE_SERIAL=${FORCE_SERIAL:-$(($(dig +noall +answer -t SOA de. @localhost | awk '{print $7}' 2>/dev/null)+1))}

# get current records from database
ZONE_RECORDS=$(mysql --batch --skip-column-names -u$DB_USERNAME -p$DB_PASSWORD $DB_NAME -e "
-- get authoritative nameservers for registered domains of TLD
select ifnull(concat(name, '. NS ', nserver1_name, '.'), '') from $DB_TABLE where not nserver1_name = '' and substring_index(name, '.', -1) = '$TLD';
select ifnull(concat(name, '. NS ', nserver2_name, '.'), '') from $DB_TABLE where not nserver2_name = '' and substring_index(name, '.', -1) = '$TLD';
select ifnull(concat(name, '. NS ', nserver3_name, '.'), '') from $DB_TABLE where not nserver3_name = '' and substring_index(name, '.', -1) = '$TLD';
-- identify which SLD nameservers need to glued in TLD zone
select ifnull(concat(nserver1_name, '. A ', nserver1_ip), '') from $DB_TABLE where not ( nserver1_name = '' or nserver1_name is null ) and not ( nserver1_ip = '' or nserver1_ip is null ) and instr(nserver1_name, name) > 0 and substring_index(name, '.', -1) = '$TLD';
select ifnull(concat(nserver2_name, '. A ', nserver2_ip), '') from $DB_TABLE where not ( nserver2_name = '' or nserver2_name is null ) and not ( nserver2_ip = '' or nserver2_ip is null ) and instr(nserver2_name, name) > 0 and substring_index(name, '.', -1) = '$TLD';
select ifnull(concat(nserver3_name, '. A ', nserver3_ip), '') from $DB_TABLE where not ( nserver3_name = '' or nserver3_name is null ) and not ( nserver3_ip = '' or nserver3_ip is null ) and instr(nserver3_name, name) > 0 and substring_index(name, '.', -1) = '$TLD';
" | grep -v "^\s*$" | sort -k1)

if [ ${PIPESTATUS[0]} -ne 0 -o ! "$ZONE_RECORDS" ]
then
	echo "ERROR: Failed to read any records for zone ${TLD}. from database." >&2
	exit ${PIPESTATUS[0]}
fi

eval "cat <<EOF >${ZONEFILE_DIR}/${TLD}.zone
$(< $TEMPLATE_DIR/${TLD}.zone.tpl)
EOF"
exit $?
