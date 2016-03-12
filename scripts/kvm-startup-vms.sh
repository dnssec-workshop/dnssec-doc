#!/bin/bash
# scripts/kvm-startup-vms.sh
# Startup VMs on KVM host

[ $UID -ne 0 ] && echo "ERROR: $0 has to be executed as root." >&2 && exit 1

set -x
set -e

/etc/init.d/libvirtd start
virsh start dnssec-rootns
virsh start dnssec-tldns
virsh start dnssec-sldns
virsh start dnssec-resolver

/etc/init.d/docker start
