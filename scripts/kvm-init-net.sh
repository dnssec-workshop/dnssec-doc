#!/bin/bash
# scripts/kvm-init-net.sh
# Init network on KVM host

set -x
set -e

# Interface name which provides internet access
INET_INTERFACE=wlan0

KVM_IFACE=br0
KVM_NET=10.20.0.0/16
KVM_IP=10.20.0.1/16

# Basic confguration of KVM network
/etc/init.d/net.${KVM_IFACE} start
ip addr flush dev ${KVM_IFACE}
ip addr add local ${KVM_IP} dev ${KVM_IFACE} scope link
route add -net ${KVM_NET} dev ${KVM_IFACE}

# Traffic der virtuellen Systeme über Interface mit Internet-Anbindungen maskieren
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -s ${KVM_NET} -o $INET_INTERFACE -j MASQUERADE
