#!/bin/sh
. /etc/default/go-server
echo 127.0.0.1 $(hostname) > /etc/hosts
chown -R go: /tmp
/bin/su - go -c /usr/share/go-server/server.sh
