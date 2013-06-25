# == Class docker-registry::service
# This class is meant to be called from docker-registry
# It ensure the service is running
class docker-registry::service {
  include docker-registry::params
  service { $docker-registry::params::service:
    ensure => running,
    enable => true,
  }
}
