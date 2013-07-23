#!/bin/sh
#
# start-kibana.sh
#
# Renders a config.js for Kibana 3 and starts Nginx
#
set -eu

test -n "${ES_PROTO}" || exit 1
test -n "${ES_HOST}"  || exit 1
test -n "${ES_PORT}"  || exit 1

cat > /src/kibana/config.js <<EOS
var config = new Settings(
{
  elasticsearch: "${ES_PROTO}://${ES_HOST}:${ES_PORT}",
  kibana_index:  "kibana-int", 
  modules:       ['histogram','map','pie','table','filtering',
                 'timepicker','text','fields','hits','dashcontrol',
                 'column','derivequeries','trends','bettermap','query'],
  }
);
EOS

exec /usr/sbin/nginx -c /etc/nginx/nginx.conf

