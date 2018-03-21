#!/bin/bash

# general diag function
function diag {
    echo "qnIPL: $1"
}

function draw_logo {
    echo "==================================="
    echo "==              ___ ____  _      =="
    echo "==   __ _ _ __ |_ _|  _ \| |     =="   
    echo "==  / _\` | \'_ \ | || |_) | |     =="
    echo "== | (_| | | | || ||  __/| |___  =="
    echo "==  \__, |_| |_|___|_|   |_____| =="
    echo "==    |_|                        =="
    echo "==================================="

}

# we need this module for network
modprobe qeth

CMDLINE=$(cat /proc/cmdline)


function get_kparam {
    REQ_PARAM=$1
    echo $CMDLINE | tr " " "\n" | grep -i "$REQ_PARAM=" | cut -d "=" -f 2-
}

function collect_vars {
    READCHAN=$(get_kparam "readchannel")
    HOSTIP=$(get_kparam "hostip")
    GW=$(get_kparam "gateway")
    DNS=$(get_kparam "Nameserver")
    SEARCH=$(get_kparam "Domain")
}

function setup_network {
    znetconf -a $READCHAN
    ip addr add $HOSTIP dev eth0
    ip link set dev eth0 up
    ip route add default via $GW dev eth0

    echo "search $SEARCH" >> /etc/resolv.conf
    echo "nameserver $DNS" >> /etc/resolv.conf
}

function collect_kern_initrd {
    SERVER=$(get_kparam "install")
    curl "$SERVER/boot/s390x/initrd" > /tmp/initrd
    curl "$SERVER/boot/s390x/linux" > /tmp/linux
}

function load_inst_kernel {
    HARDCODED_CMDLINE="instnetdev=osa layer2=1 portno=1 OSAInterface=qdio OSAHWAddress="
    kexec -l /tmp/linux --initrd=/tmp/initrd --command-line="$CMDLINE $HARDCODED_CMDLINE"
    kexec -e
}


echo "===== Starting qnIPL =====\n"
draw_logo
collect_vars
setup_network
collect_kern_initrd
load_inst_kernel
