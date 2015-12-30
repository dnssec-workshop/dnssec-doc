#!/bin/bash
# scripts/kvm-startup-vms.sh
# Startup VMs on KVM host

set -x
set -e

/etc/init.d/libvirtd start
virsh start dnssec-rootns
virsh start dnssec-tldns
#virsh start dnssec-sldns
#virsh start dnssec-resolver
