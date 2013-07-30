#!/bin/bash

apt-get update
apt-get install ruby1.9.1-dev rubygems build-essential libxslt1-dev libxml2-dev unzip git-core -y
gem1.9.1 install bundler
mkdir -p /var/cache/omnibus
chown -R go: /var/cache/omnibus
chown -R go: /opt
