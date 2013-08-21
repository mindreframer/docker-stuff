#!/bin/sh
# Start etcd.
ETCD="/etcd/bin/etcd"
HOSTNAME=$(hostname)
IPADDRESS=$(
    ip -o -4 addr show dev eth0 |
    cut -d' ' -f7 |
    cut -d'/' -f1
)

echo 127.0.0.1 $HOSTNAME > /etc/hosts
echo $IPADDRESS $HOSTNAME >> /etc/hosts

$ETCD -vv -h $IPADDRESS $@
