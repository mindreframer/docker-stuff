#!/bin/sh
. /etc/default/go-agent
chown -R go: /tmp
echo 127.0.0.1 $(hostname) > /etc/hosts
/bin/su - go -c /usr/share/go-agent/agent.sh
