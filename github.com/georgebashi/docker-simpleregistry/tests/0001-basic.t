#!/usr/bin/env bats
# vim: set ai et sw=2 sts=2 ft=sh:

test_description="basic requests"

. ./common.sh
. ./sharness.sh

test_expect_success "ping" "
  $C $H/_ping | grep true
"

test_expect_success "home" "
  $C $H | grep -E '\".+\"'
"

test_expect_success "get image layer 404" "
  $Cs $H/v1/images/I_DONT_EXIST/layer | grep 404
"

test_expect_success "get image json 404" "
  $Cs $H/v1/images/I_DONT_EXIST/json | grep 404
"

test_expect_success "get image ancestry 404" "
  $Cs $H/v1/images/I_DONT_EXIST/ancestry | grep 404
"

test_done
