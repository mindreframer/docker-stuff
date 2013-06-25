# == Class docker-registry::intall
# This class is meant to be called from docker-registry
# It install requires packages
class docker-registry::install {
  include docker-registry::params
  package { $docker-registry::params::pkgname:
    ensure => present,
  }
}
