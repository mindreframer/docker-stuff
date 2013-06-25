#!/usr/bin/env bash
# vim: set ai et sw=2 sts=2 ft=sh:

test_description="test uploading an image"

. ./common.sh
. ./sharness.sh


test_expect_success "put_image_json: invalid json" "
  test_must_fail $C -f -X PUT -d 'LOL{WTF' -H 'Content-Type: application/json' $H/v1/images/foo/json
"

test_expect_success "put_image_json: valid request" "
  $C -f -X PUT $H/v1/images/foo/json -d '{\"id\":\"foo\"}' -H 'Content-Type: application/json' -H 'X-Docker-Checksum: sha256:9483ca9ae94c16bd8f0f7e3ad5773edd843c8825ef622d73e55b05402b8b025f'
"

test_expect_success "get_image_json" "
  $C $H/v1/images/foo/json
"

test_expect_success "put_image_layer: bad data" "
  $C -X PUT $H/v1/images/foo/layer -d 'oowtf' -H 'Content-Type: application/octet-stream' | grep 'Checksum mismatch'"

test_expect_success "put_image_layer: correct data" "
  $C -f -X PUT $H/v1/images/foo/layer -d 'lolol' -H 'Content-Type: application/octet-stream'"

test_expect_success "get_image_ancestry" "
  $C $H/v1/images/foo/ancestry | tr '\n' ' ' | grep -E '[\s*\"foo\"\s*]'"

test_done
