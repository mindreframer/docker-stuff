# install Go system-wide
echo deb http://archive.ubuntu.com/ubuntu precise main universe multiverse > /etc/apt/sources.list
apt-get update

# Build dependencies
apt-get install -y -q curl git mercurial build-essential

# Install Go
curl -s https://go.googlecode.com/files/go1.1.1.linux-amd64.tar.gz | tar -v -C /usr/local -xz
export PATH=/usr/local/go/bin:$PATH
cd /tmp && echo 'package main' > t.go && go test -a -i -v
rm -rf /var/cache/apt/archives/*.deb
