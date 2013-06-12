#
# Cookbook Name:: docker
# Recipe:: default
#
# Copyright (C) 2013 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

case node['docker']['install_method']
when 'ppa'
  include_recipe 'docker::install-ppa'
end
