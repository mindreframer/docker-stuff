# Dockland

Yet another docker web ui.

## Requirements

* Ruby >= 1.9
* graphviz

## Usage

    git clone https://github.com/dynport/dockland.git /opt/dockland
    cd /opt/dockland
    bundle
    bundle exec ./bin/dockland -h <DOCKER_API_HOST>

    open http://127.0.0.1:9292

## Deploying dockland inside a docker container

### Dockerfile
    # /tmp/dockland.dockerfile
    FROM ubuntu:12.04

    RUN sed 's/main$/main universe/' -i /etc/apt/sources.list && apt-get update && apt-get upgrade -y
    RUN apt-get install ruby1.9.1 ruby1.9.1-dev build-essential git-core graphviz libssl-dev -y

    RUN git clone https://github.com/dynport/dockland.git /app

    # this is to speed up updates
    RUN cd /app && gem install bundler --no-ri --no-rdoc && bundle

    # change the revision to update your image
    ENV APP_REVISION 51f5445abeeb080568edeca248d68b29a66f1387
    RUN cd /app && git fetch -q origin  && git reset -q --hard $APP_REVISION && git clean -q -d -x -f && bundle

    EXPOSE 80

    CMD cd /app && bundle exec ./bin/dockland -h ${DOCKER_HOST-http://172.16.42.1:4243} -p 80

### Build Image

    $ docker build -t dockland:dockland - < /tmp/dockland.dockerfile

### Startup

    $ id=$(docker run -d dockland:dockland)
    $ curl -I http://127.0.0.1:$(docker port $id 80)


In that case you would need to bind the docker daemon either on the `0.0.0.0` (so you probably want to have some firewall setup) or the `172.16.42.1` interface as the default now seems to be the `127.0.0.1` interface.

    /opt/docker/bin/docker -H <0.0.0.0|172.16.42.1> -d 2>&1 | logger -t docker &

You can use an provide an alternative docker host like this

    docker run -e DOCKER_HOST=http://docker.host:4243 -d dockland:dockland

## To come

* fetch image graph in parallel
* add more information to frontend
* add features like:
  * cleanup dead containers
  * cleanup images without tags
  * ...
