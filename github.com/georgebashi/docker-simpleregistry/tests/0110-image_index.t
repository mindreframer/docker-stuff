#!/usr/bin/env bash
# vim: set ai et sw=2 sts=2 ft=sh:

test_description="index operations for uploading an image"

. ./common.sh
. ./sharness.sh

test_expect_success "put_image" "
  $C -f -X PUT $H/v1/repositories/foo/bar/images -d '[{\"checksum\": \"sha256:9483ca9ae94c16bd8f0f7e3ad5773edd843c8825ef622d73e55b05402b8b025f\", \"id\": \"foo\"}]' -H 'Content-Type: application/octet-stream'
"

test_expect_success "get_image" "
  $C $H/v1/repositories/foo/bar/images | grep 9483ca9ae94c16bd8f0f7e3ad5773edd843c8825ef622d73e55b05402b8b025f
"

test_done
