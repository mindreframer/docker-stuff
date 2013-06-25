# Docker SimpleRegistry

## What?
Docker SimpleRegistry is a standalone reimplementation of the docker registry and index in Go, intended for people who'd like to use Docker privately, without publishing their containers to the public registry. It's distributed as a single binary which stores container images in `$PWD`.

## Status
Currently, I've implemented the full [Registry API](http://docs.docker.io/en/latest/api/registry_api.html), and I've stubbed out the [Index API](http://docs.docker.io/en/latest/api/registry_api.html#images-index) to accept any login (as there is no authentication right now). There's a bash test suite included in the tests directory, which can run against both a local install of [dotcloud/docker-registry](http://github.com/dotcloud/docker-registry) and this project, to ensure correctness.

### TODO
Things I'll be adding Real Soon Now&trade;:

* Index search API
* Configuration of image store path

Things I don't have a use for so won't be writing myself, but am happy to accept patches for:

* Other storage backends (i.e. S3)
* Authentication
* Ability to work as an index for [dotcloud/docker-registry](http://github.com/dotcloud/docker-registry)

## Installation

    go build
    ./docker-simpleregistry

## News


## Issues
Report any issues you find using the [issues tab](https://github.com/georgebashi/docker-simpleregistry/issues) above.

## License
Apache 2.0, like the rest of Docker. A copy is included in the LICENSE file.
