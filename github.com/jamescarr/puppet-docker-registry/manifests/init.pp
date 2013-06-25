# == Class: docker-registry
#
# Full description of class docker-registry here.
#
# === Parameters
#
# Document parameters here.
#
# [*s3_access_key*]
# For accessing s3
#
# [*s3_secret_key*]
# Yah... for accessing s3
#
# [*s3_bucket*]
# Where to store your images in s3
#
# [*smtp_host*]
# The host for smtp server
# 
# [*smtp_user*]
# The user to connect to smtp server as
#
# [*smtp_password*]
# The password for that user
# 
#
# === Examples
#
#  include docker-registry
#
#  class { docker-registry:
#    s3_access_key => 'yeahrightasif',
#    s3_secret_key => '3hqv3vhji4hr892q34rghv3rv',
#    s3_bucket     => 'docker-images',
#  }
#
# === Authors
#
# James Carr <james@zapier.com>
#
# === Copyright
#
# Copyright 2013 Your James Carr, unless otherwise noted.
#
class docker-registry (
  $s3_access_key = 'CHANGEME',
  $s3_secret_key = 'CHANGEME',
  $s3_bucket = 'CHANGEME',
  $smtp_host = '',
  $smtp_login = '',
  $smtp_password = '',
) {
  include ::git
  include ::supervisor
 
  $app        = 'docker-registry'
  $virtualenv = "/usr/local/lib/virtualenvs/$app"
  $app_user   = 'docker_registar'
  $app_dir    = '/usr/srv/docker-registry'

  package { 
    'build-essential': ensure => present;
    'libevent-dev':    ensure => present;
  }

  user { $app_user:
    ensure => present,

  }
  class { 'python':
    version    => 'system',
    dev        => true,
    virtualenv => true,
    gunicorn   => false,
  }

  file { '/usr/local/lib/virtualenvs':
    ensure => directory,
    owner  => $app_user,
    before => Python::Virtualenv[$virtualenv],
  }

  python::virtualenv { $virtualenv:
    ensure       => present,
    requirements => '/usr/srv/docker-registry/requirements.txt',
    require      => [
      Package['build-essential'], 
      Package['libevent-dev'], 
      User[$app_user],
      Git::Repo[$app]
    ],
    owner => $app_user,
    group => $app_user,
  }

  git::repo { $app:
    source => 'git://github.com/dotcloud/docker-registry.git',
    path   => $app_dir,
    update => true,
    branch => 'master',
    require => Class['git'],
  }

  # config file
  file { "$app_dir/config.yml":
    ensure  => present,
    mode    => 0644,
    content => template('docker-registry/config.yml.erb'),
  }

  $stdout_log     = "/var/log/supervisor/${app}_out.log"
  $stderr_log     = "/var/log/supervisor/${app}_err.log"

  file { [$stdout_log, $stderr_log]:
    ensure  => present,
    owner   => $app_user,
    group   => $app_user,
    mode    => '0644'
  }
  supervisor::service { $app: 
    command        => "$virtualenv/bin/gunicorn -b 0.0.0.0:5000 -w 5 wsgi:application",
    ensure         => present,
    enable         => true,
    user           => $app_user,
    stdout_logfile => $stdout_log,
    stderr_logfile => $stderr_log,
    startsecs      => 10,
    priority       => 10,
    directory      => $app_dir,
    autorestart    => true,
    require        => Python::Virtualenv[$virtualenv],
  }
  
  file { '/etc/nginx/sites-enabled/default':
    ensure => absent,
  }

  # pnginx
  $upstream    = $app
  $server_name = 'dockerregistry' 
  class { '::nginx':
    template    => 'docker-registry/nginx.conf.erb',
  }
  nginx::resource::upstream { $app:
    ensure  => present,
    members => [
      'localhost:5000', 
    ],
    require => Supervisor::Service[$app],
  }
}
