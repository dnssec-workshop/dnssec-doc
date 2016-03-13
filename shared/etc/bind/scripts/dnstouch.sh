#!/bin/bash
# dnstouch.sh
# Increment the SOA serial in a zone file

perl -pi -e "s/(.*\s+SOA\s+[^\s]+\s+[^\s]+[\s\(]*)\s+[0-9]+(.*)/\$1 $(date +%s)\$2/m" $@
exit $?
