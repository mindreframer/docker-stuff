# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.define "docker" do |vm_config|
    vm_config.vm.box = "precise"
    vm_config.vm.box_url = "http://files.vagrantup.com/precise64.box"
    vm_config.vm.network :hostonly, "192.168.35.2"
    vm_config.vm.customize ["modifyvm", :id, "--rtcuseutc", "on"]
    vm_config.vm.customize ["modifyvm", :id, "--memory", 4096]
    vm_config.vm.customize ["modifyvm", :id, "--cpus", 2]
    vm_config.vm.customize ["modifyvm", :id, "--name", "docker"]
  end
end
