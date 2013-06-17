# DEBIAN_FRONTEND=noninteractive
# 
# apt-get update
# apt-get upgrade -y
# apt-get install -y linux-generic-lts-raring bsdtar build-essential git-core lxc golang
# echo "golang-go	golang-go/dashboard	boolean false" | debconf-set-selections -
# 
# git clone https://github.com/dotcloud/docker.git /opt/docker.git
# cd /opt/docker.git
# 
# make VERBOSE=1
# cp /opt/docker.git/bin/docker /usr/local/bin/docker

cat - > /etc/init.d/docker << EOF
#!/usr/bin/env bash

PID_PATH=/var/run/docker.pid
BIN_PATH=/usr/local/bin/docker

function set_status {
  if [ ! -e \$PID_PATH ]; then
    status="stopped"
  elif [[ ! \$(ps -o cmd -p \$(cat \$PID_PATH) | grep \$BIN_PATH) ]]; then
    status="crashed?!? (pidfile exists but seems to be not running)"
  else
    status="running with pid \$(cat \$PID_PATH)"
    pid=\$(cat \$PID_PATH)
    running=true
  fi
}

case \$1 in
  "start")
    set_status
    if [[ \$running ]]; then
      echo "ERROR: already running \$pid"
      exit 1
    fi
    \$BIN_PATH -H=0.0.0.0 -D -d 2>&1 | logger -t docker &
    for i in \$(seq 1 100); do
      if [ -e \$PID_PATH ]; then
        echo "started with pid \$pid"
        exit 0
      fi
      sleep 0.1
    done
    echo "unable to start"
    exit 1
    ;;
  "status")
    set_status
    echo "STATUS: \$status"
    if [[ ! \$running ]]; then
      exit 1
    else
      exit 0
    fi
    ;;
  "stop")
    set_status
    if [[ ! \$running ]]; then
      echo "ERROR: not running"
      exit 0
    else
      echo "stopping \$pid"
      kill \$pid
      echo "stopped"
    fi
    ;;
  *)
    echo "$1 is not supported"
    exit 1
esac
EOF

chmod 0755 /etc/init.d/docker
