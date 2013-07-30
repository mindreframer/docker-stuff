#!/bin/bash
apt-get update
apt-get install default-jre unzip git-core -y
dpkg -i /tmp/go-server.deb
rm /tmp/go-server.deb
