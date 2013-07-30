#!/bin/bash
apt-get update
apt-get install default-jre unzip git-core -y
dpkg -i /tmp/go-agent.deb
rm /tmp/go-agent.deb
