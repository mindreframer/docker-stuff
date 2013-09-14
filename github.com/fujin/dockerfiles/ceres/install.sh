#!/bin/sh

rm -rf /var/cache/apt/archives/*

#apt-get install wget ca-certificates python2.7-dev -yq
echo deb http://nz.archive.ubuntu.com/ubuntu precise main universe multiverse > /etc/apt/sources.list
apt-get update -qq
apt-get install wget ca-certificates python-pip -yqq

mkdir -p /ceres
cd /ceres

wget -q https://github.com/graphite-project/ceres/archive/master.tar.gz -O - | tar zxv --strip-components=1
# wget -q https://raw.github.com/pypa/pip/master/contrib/get-pip.py -O - | python
# wget -q https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -O - | python2.7

pip install -r requirements.txt --use-mirrors
python setup.py install
