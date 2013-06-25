# == Class docker-registry::config
# This class is meant to be called from docker-registry
# it bakes the configuration file
# === Parameters
#
# [*options*]
#   A hash of extra options to set in the configuration
#
# === Example
#
#  class { docker-registry:
#    options => {
#      'key1' => 'value1',
#      'key2' => 'value2',
#    }
#  }
class docker-registry::config(
    $servers=$docker-registry::servers,
    $options=$docker-registry::options,
    ) {
  include docker-registry::params
  file { $docker-registry::params::conffile:
    ensure  => present,
    mode    => '0440',
    content => template('docker-registry/docker-registry.conf.erb')
  }
}

