if (!node['kernel']['modules'].has_key?("aufs") &&
    node['docker']['kernel_package']) then
  package "#{node['docker']['kernel_package']}" do
    action :install
  end

  if node.has_key?('rackspace') && node['docker']['menu_lst'] then
    template "/boot/grub/menu.lst"
  end

  log "kernel-installed" do
    message "A kernel supporting aufs has been installed.  You should now reboot."
  end
end
