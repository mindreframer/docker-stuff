# == Class docker-registry::params
# This class is meant to be called from docker-registry
# It set variable according to platform
class docker-registry::params {
  $pkgname = 'docker-registry'
  $conffile = 'docker-registry/etc/docker-registry.conf'
  $service = $::osfamily ? {
    'Debian' => 'docker-registry',
    'RedHat' => 'docker-registry',
    default  => fail('unsupported platform')
  }
}
