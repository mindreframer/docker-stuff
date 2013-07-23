# Kibana 3

Kibana - http://three.kibana.org/

Nginx - http://wiki.nginx.org/Main/

# Using the container

The container expects environment variables for your Elasticsearch service to
be passed through from `docker run` (see the command below).

```shell
$ docker pull andrewh/kibana3
```

```shell
$ docker run -e ES_PROTO=https \
             -e ES_HOST=localhost \
             -e ES_PORT=443 \
             -p 8080:8080 \
             -m 0 \
             andrewh/kibana3 \
             sh -ex /src/start-kibana.sh
```

The Puppet module from @garethr makes all this very easy, but the above will
give you a working Kibana on port 8080.

# Thanks

@nickstenning for the nginx.conf and help with Docker

