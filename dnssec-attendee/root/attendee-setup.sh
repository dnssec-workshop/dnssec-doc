#!/bin/bash
# Configure the attendee system for workshop

set -e
[ $UID -ne 0 ] && echo "ERROR: You need to be root for this." && false

read -p "Insert your network device name [eth0]>" NSIFACE
NSIFACE=${NSIFACE:-"eth0"}

read -p "Insert your attendee ID [32-255]>" NSID
BASENET=10.20.0.0
NETPREFIX=10.20.${NSID}
NETSIZE=16
NSIFACE=eth0
NETGATEWAY=10.20.0.1

NAMED_BASEDIR=/root/dnssec-workshop

link_status=`ip link show dev ${NSIFACE}`
echo "Your link state: $link_status"
echo "$link_status" | grep "state UP"

ip addr add local ${NETPREFIX}.3/${NETSIZE} dev ${NSIFACE} scope link label ${NSIFACE}.client
ip addr add local ${NETPREFIX}.13/${NETSIZE} dev ${NSIFACE} scope link label ${NSIFACE}.master
ip addr add local ${NETPREFIX}.19/${NETSIZE} dev ${NSIFACE} scope link label ${NSIFACE}.slave
ip addr add local ${NETPREFIX}.18/${NETSIZE} dev ${NSIFACE} scope link label ${NSIFACE}.resolver
route add -net ${BASENET}/${NETSIZE} dev ${NSIFACE}
route add -net default gw ${NETGATEWAY}

echo "Your network configuration:"
ip addr show dev ${NSIFACE}
route -n
